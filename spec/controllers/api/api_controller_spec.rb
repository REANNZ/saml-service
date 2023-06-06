require 'rails_helper' # rubocop:disable Style/FrozenStringLiteralComment

require 'gumboot/shared_examples/api_controller'

RSpec.describe API::APIController, type: :controller do
  def auth_type(type)
    allow(Rails.application.config.saml_service.api).to receive(:authentication).and_return(type)
  end

  context 'requesting resource that does not exist' do
    let(:api_subject) { create(:api_subject, :x509_cn) }

    controller(API::APIController) do
      def missing_resource
        public_action
        raise(API::APIController::ResourceNotFound)
      end
    end

    before do
      auth_type(:x509)
      request.headers['HTTP_X509_DN'] = +"CN=#{api_subject.x509_cn}"
      @routes.draw do
        get '/api/missing_resource' => 'api/api#missing_resource'
      end
      get :missing_resource
    end

    subject { response }
    let(:data) { response.parsed_body }

    it {
      is_expected.to have_http_status(:not_found)
      expect(data['message']).to match(/Resource not found/)
    }
  end

  context 'a bad request' do
    let(:api_subject) { create(:api_subject, :x509_cn) }
    before do
      auth_type(:x509)
      request.headers['HTTP_X509_DN'] = +"CN=#{api_subject.x509_cn}"
      @routes.draw do
        get '/api/a_bad_request' => 'api/api#a_bad_request'
      end
      get :a_bad_request
    end

    controller(API::APIController) do
      def a_bad_request
        public_action
        raise(API::APIController::BadRequest)
      end
    end

    subject { response }
    let(:data) { response.parsed_body }

    it {
      is_expected.to have_http_status(:bad_request)
      expect(data['message']).to match(/Bad request/)
    }
  end

  include_examples 'Anon controller'

  before do
    @routes.draw do
      get '/anonymous/an_action' => 'api/api#an_action'
      get '/anonymous/bad_action' => 'api/api#bad_action'
      get '/anonymous/public' => 'api/api#public'
    end
  end

  it { is_expected.to respond_to(:subject) }

  context '#ensure_authenticated as before_action' do
    subject { response }
    let(:json) { JSON.parse(subject.body) }

    context 'invalid authentication method' do
      before do
        auth_type(nil)
        get :an_action
      end

      it {
        is_expected.to have_http_status(:forbidden)
        expect(json['message']).to eq('The request was understood but explicitly denied.')
      }
    end

    context 'invalid authentication' do
      before do
        allow(Rails.application.config.saml_service).to receive(:api).and_return(nil)
        get :an_action
      end

      it {
        is_expected.to have_http_status(:forbidden)
        expect(json['message']).to eq('The request was understood but explicitly denied.')
      }
    end

    context 'unknown authentication method' do
      before do
        auth_type(:unknown)
        get :an_action
      end

      it {
        is_expected.to have_http_status(:forbidden)
        expect(json['message']).to eq('The request was understood but explicitly denied.')
      }
    end

    context 'x509 authentication' do
      before do
        auth_type(:x509)
      end

      context 'no x509 header set by nginx' do
        before { get :an_action }

        it {
          is_expected.to have_http_status(:unauthorized)
          expect(json['message']).to eq('Client request failure.')
          expect(json['error']).to eq('x509 API authentication method not provided')
        }
      end

      context 'x509 header set to "(null)"' do
        before do
          request.headers['HTTP_X509_DN'] = '(null)'
          get :an_action
        end

        it {
          is_expected.to have_http_status(:unauthorized)
          expect(json['message']).to eq('Client request failure.')
          expect(json['error']).to eq('x509 API authentication method not provided')
        }
      end

      context 'invalid x509 header set by nginx' do
        before do
          request.headers['HTTP_X509_DN'] = "Z=#{Faker::Lorem.word}"
          get :an_action
        end

        it {
          is_expected.to have_http_status(:unauthorized)
          expect(json['message']).to eq('Client request failure.')
          expect(json['error']).to eq('Subject DN invalid')
        }
      end

      context 'without a CN component to DN' do
        before do
          request.headers['HTTP_X509_DN'] = "O=#{Faker::Lorem.word}"
          get :an_action
        end

        it {
          is_expected.to have_http_status(:unauthorized)
          expect(json['message']).to eq('Client request failure.')
          expect(json['error']).to eq('Subject CN invalid')
        }
      end

      context 'with a CN that does not represent an APISubject' do
        before do
          request.headers['HTTP_X509_DN'] = "/CN=#{Faker::Lorem.word}/" \
                                            "O=#{Faker::Lorem.word}"
          get :an_action
        end

        it {
          is_expected.to have_http_status(:unauthorized)
          expect(json['message']).to eq('Client request failure.')
          expect(json['error']).to eq('Subject invalid')
        }
      end
    end

    context 'token authentication' do
      before do
        auth_type(:token)
      end

      context 'no authorization header provided by client' do
        before do
          request.headers['Authorization'] = nil
          get :an_action
        end

        it {
          is_expected.to have_http_status(:unauthorized)
          expect(json['message']).to eq('Client request failure.')
          expect(json['error']).to eq('Token API authentication method not provided')
        }
      end

      context 'invalid authorization header provided by client' do
        before do
          request.headers['Authorization'] = "Z #{Faker::Lorem.word}"
          get :an_action
        end

        it {
          is_expected.to have_http_status(:unauthorized)
          expect(json['message']).to eq('Client request failure.')
          expect(json['error']).to eq('Invalid Authorization header value')
        }
      end

      context 'with a token that does not represent an APISubject' do
        before do
          request.headers['Authorization'] = 'Bearer 123'
          get :an_action
        end

        it {
          is_expected.to have_http_status(:unauthorized)
          expect(json['message']).to eq('Client request failure.')
          expect(json['error']).to eq('Subject invalid')
        }
      end
    end

    context 'with an APISubject that is not functioning' do
      let(:api_subject) { create :api_subject, :x509_cn, enabled: false }

      before do
        auth_type(:x509)
        request.headers['HTTP_X509_DN'] = "/CN=#{api_subject.x509_cn}/" \
                                          "O=#{Faker::Lorem.word}"
        get :an_action
      end

      it {
        is_expected.to have_http_status(:unauthorized)
        expect(json['message']).to eq('Client request failure.')
        expect(json['error']).to eq('Subject not functional')
      }
    end
  end

  context '#ensure_access_checked as after_action' do
    subject(:api_subject) { create :api_subject, :x509_cn }
    let(:json) { response.parsed_body }

    RSpec.shared_examples 'APIController base state' do
      it 'fails request to incorrectly implemented action' do
        msg = 'No access control performed by API::APIController#bad_action'
        expect { get :bad_action }.to raise_error(msg)
      end

      it 'completes request to a public action' do
        get :public
        expect(response).to have_http_status(:ok)
      end
    end

    context 'subject without permissions' do
      before do
        auth_type(:x509)
        request.headers['HTTP_X509_DN'] = "/CN=#{api_subject.x509_cn}/DC=example"
      end

      include_examples 'APIController base state'

      it 'has no permissions' do
        expect(api_subject.permissions).to eq([])
      end

      context 'the request does not complete' do
        before { get :an_action }
        it 'should respond with status code :forbidden (403)' do
          expect(response).to have_http_status(:forbidden)
          expect(json['message'])
            .to eq('The request was understood but explicitly denied.')
        end
      end
    end

    context 'subject with invalid permissions' do
      before do
        request.headers['HTTP_X509_DN'] = "/CN=#{api_subject.x509_cn}/DC=example"
        auth_type(:x509)
      end
      subject(:api_subject) do
        create :api_subject, :x509_cn, :authorized, permission: 'invalid:permission'
      end

      include_examples 'APIController base state'

      it 'has an invalid permission' do
        expect(api_subject.permissions).to eq(['invalid:permission'])
      end

      context 'the request does not complete' do
        before { get :an_action }
        it 'should respond with status code :forbidden (403)' do
          expect(response).to have_http_status(:forbidden)
          expect(json['message'])
            .to eq('The request was understood but explicitly denied.')
        end
      end
    end

    context 'subject with x509 authentication and valid permission' do
      before do
        request.headers['HTTP_X509_DN'] = "/CN=#{api_subject.x509_cn}/DC=example"
        auth_type(:x509)
      end
      subject(:api_subject) do
        create :api_subject, :x509_cn, :authorized, permission: 'required:permission'
      end

      include_examples 'APIController base state'

      it 'has a valid permission' do
        expect(api_subject.permissions).to eq(['required:permission'])
      end

      it 'completes request after permissions checked' do
        get :an_action
        expect(response).to have_http_status(:ok)
      end
    end

    context 'subject with token authentication and valid permission' do
      before do
        request.headers['Authorization'] = "Bearer #{api_subject.token}"
        auth_type(:token)
      end
      subject(:api_subject) do
        create :api_subject, :token, :authorized, permission: 'required:permission'
      end

      include_examples 'APIController base state'

      it 'has a valid permission' do
        expect(api_subject.permissions).to eq(['required:permission'])
      end

      it 'completes request after permissions checked' do
        get :an_action
        expect(response).to have_http_status(:ok)
      end
    end
  end
end

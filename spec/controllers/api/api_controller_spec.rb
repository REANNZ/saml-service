require 'rails_helper' # rubocop:disable Style/FrozenStringLiteralComment

require 'gumboot/shared_examples/api_controller'

RSpec.describe API::APIController, type: :controller do
  def auth_type(type)
    allow(Rails.application)
      .to receive_message_chain(:config, :saml_service, :api, :authentication)
      .and_return(type)
  end

  context 'requesting resource that does not exist' do
    let(:api_subject) { create(:api_subject, :x509_cn) }

    before do
      auth_type(:x509)
      request.headers['HTTP_X509_DN'] = +"CN=#{api_subject.x509_cn}"
    end

    controller(API::APIController) do
      def missing_resource
        public_action
        raise(API::APIController::ResourceNotFound)
      end
    end

    before do
      @routes.draw do
        get '/api/missing_resource' => 'api/api#missing_resource'
      end
    end

    before { get :missing_resource }
    subject { response }
    let(:data) { JSON.parse(response.body) }

    it { is_expected.to have_http_status(:not_found) }

    it 'responds with the exception' do
      expect(data['message']).to match(/Resource not found/)
    end
  end

  context 'a bad request' do
    let(:api_subject) { create(:api_subject, :x509_cn) }
    before do
      auth_type(:x509)
      request.headers['HTTP_X509_DN'] = +"CN=#{api_subject.x509_cn}"
    end

    controller(API::APIController) do
      def a_bad_request
        public_action
        raise(API::APIController::BadRequest)
      end
    end

    before do
      @routes.draw do
        get '/api/a_bad_request' => 'api/api#a_bad_request'
      end
    end

    before { get :a_bad_request }
    subject { response }
    let(:data) { JSON.parse(response.body) }

    it { is_expected.to have_http_status(:bad_request) }

    it 'responds with the exception' do
      expect(data['message']).to match(/Bad request/)
    end
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

      it { is_expected.to have_http_status(:forbidden) }

      context 'json within response' do
        it 'has a message' do
          expect(json['message']).to eq('The request was understood but explicitly denied.')
        end
      end
    end

    context 'unknown authentication method' do
      before do
        auth_type(:unknown)
        get :an_action
      end

      it { is_expected.to have_http_status(:forbidden) }

      context 'json within response' do
        it 'has a message' do
          expect(json['message']).to eq('The request was understood but explicitly denied.')
        end
      end
    end

    context 'x509 authentication' do
      before do
        auth_type(:x509)
      end

      context 'no x509 header set by nginx' do
        before { get :an_action }

        it { is_expected.to have_http_status(:unauthorized) }

        context 'json within response' do
          it 'has a message' do
            expect(json['message']).to eq('Client request failure.')
          end
          it 'has an error' do
            expect(json['error']).to eq('x509 API authentication method not provided')
          end
        end
      end

      context 'x509 header set to "(null)"' do
        before do
          request.headers['HTTP_X509_DN'] = '(null)'
          get :an_action
        end

        it { is_expected.to have_http_status(:unauthorized) }
        context 'json within response' do
          it 'has a message' do
            expect(json['message']).to eq('Client request failure.')
          end
          it 'has an error' do
            expect(json['error']).to eq('x509 API authentication method not provided')
          end
        end
      end

      context 'invalid x509 header set by nginx' do
        before do
          request.headers['HTTP_X509_DN'] = "Z=#{Faker::Lorem.word}"
          get :an_action
        end

        it { is_expected.to have_http_status(:unauthorized) }
        context 'json within response' do
          it 'has a message' do
            expect(json['message']).to eq('Client request failure.')
          end
          it 'has an error' do
            expect(json['error']).to eq('Subject DN invalid')
          end
        end
      end

      context 'without a CN component to DN' do
        before do
          request.headers['HTTP_X509_DN'] = "O=#{Faker::Lorem.word}"
          get :an_action
        end

        it { is_expected.to have_http_status(:unauthorized) }
        context 'json within response' do
          it 'has a message' do
            expect(json['message']).to eq('Client request failure.')
          end
          it 'has an error' do
            expect(json['error']).to eq('Subject CN invalid')
          end
        end
      end

      context 'with a CN that does not represent an APISubject' do
        before do
          request.headers['HTTP_X509_DN'] = "/CN=#{Faker::Lorem.word}/" \
                                        "O=#{Faker::Lorem.word}"
          get :an_action
        end

        it { is_expected.to have_http_status(:unauthorized) }
        context 'json within response' do
          it 'has a message' do
            expect(json['message']).to eq('Client request failure.')
          end
          it 'has an error' do
            expect(json['error']).to eq('Subject invalid')
          end
        end
      end
    end

    context 'token authentication' do
      before do
        auth_type(:token)
      end

      context 'invalid authorization header provided by client' do
        before do
          request.headers['Authorization'] = "Z #{Faker::Lorem.word}"
          get :an_action
        end

        it { is_expected.to have_http_status(:unauthorized) }
        context 'json within response' do
          it 'has a message' do
            expect(json['message']).to eq('Client request failure.')
          end
          it 'has an error' do
            expect(json['error']).to eq('Invalid Authorization header value')
          end
        end
      end

      context 'with a token that does not represent an APISubject' do
        before do
          request.headers['Authorization'] = 'Bearer 123'
          get :an_action
        end

        it { is_expected.to have_http_status(:unauthorized) }
        context 'json within response' do
          it 'has a message' do
            expect(json['message']).to eq('Client request failure.')
          end
          it 'has an error' do
            expect(json['error']).to eq('Subject invalid')
          end
        end
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

      it { is_expected.to have_http_status(:unauthorized) }
      context 'json within response' do
        it 'has a message' do
          expect(json['message']).to eq('Client request failure.')
        end
        it 'has an error' do
          expect(json['error']).to eq('Subject not functional')
        end
      end
    end
  end

  context '#ensure_access_checked as after_action' do
    subject(:api_subject) { create :api_subject, :x509_cn }
    let(:json) { JSON.parse(response.body) }

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
        end
        it 'recieves a json message' do
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
        end
        it 'recieves a json message' do
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

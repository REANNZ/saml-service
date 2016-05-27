require 'rails_helper'

RSpec.describe API::RawEntityDescriptorsController, type: :controller do
  describe 'post :create' do
    let(:entity_source) { create(:entity_source) }
    let(:source_tag) { entity_source.source_tag }

    let(:raw_idp) { create(:raw_entity_descriptor_idp) }
    let(:keys) { [:xml, :created_at, :updated_at, :enabled] }
    let(:idp_values) { raw_idp.values.slice(*keys) }
    let(:idp_tags) { { tags: [Faker::Lorem.word, Faker::Lorem.word] } }

    let(:raw_entity_descriptor) { idp_values.merge(idp_tags) }

    def run
      request.env['HTTP_X509_DN'] = "CN=#{api_subject.x509_cn}" if api_subject
      post :create, tag: source_tag,
                    raw_entity_descriptor: raw_entity_descriptor
    end

    context 'not permitted' do
      let(:api_subject) { create(:api_subject) }
      before { run }
      subject { response }
      it { is_expected.to have_http_status(:forbidden) }
      it 'responds with a message' do
        data = JSON.load(response.body)
        expect(data['message']).to match(/explicitly denied/)
      end
    end

    context 'permitted' do
      let(:api_subject) { create(:api_subject, :authorized, permission: '*') }

      subject do
        run
        response
      end

      context 'with an entity source that does not exist' do
        let(:source_tag) { Faker::Lorem.word }
        it { is_expected.to have_http_status(:not_found) }
      end

      context 'with valid params' do
        it { is_expected.to have_http_status(:ok) }
      end

      context 'with empty raw entity descriptor' do
        let(:raw_entity_descriptor) { {} }
        subject { -> { run } }
        it { is_expected.to raise_error(ActionController::ParameterMissing) }
      end

      context 'with missing xml' do
        let(:keys) { [:created_at, :updated_at, :enabled] }
        it { is_expected.to have_http_status(:bad_request) }
      end

      context 'with missing created at' do
        let(:keys) { [:xml, :updated_at, :enabled] }
        it { is_expected.to have_http_status(:bad_request) }
      end

      context 'with missing updated at' do
        let(:keys) { [:xml, :created_at, :enabled] }
        it { is_expected.to have_http_status(:bad_request) }
      end

      context 'with missing enabled flag' do
        let(:keys) { [:xml, :created_at, :updated_at, :updated_at] }
        it { is_expected.to have_http_status(:bad_request) }
      end
    end
  end
end

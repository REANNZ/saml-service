# frozen_string_literal: true
require 'rails_helper'

RSpec.describe API::DiscoveryEntitiesController, type: :controller do
  let(:api_subject) { create(:api_subject, :authorized, permission: '*') }
  let!(:identity_provider) { create(:entity_descriptor) }
  let!(:service_provider) { create(:entity_descriptor) }

  let!(:idp_sso_descriptor) do
    create(:idp_sso_descriptor, entity_descriptor: identity_provider)
  end

  let!(:raw_ed_idp) do
    create(:raw_entity_descriptor_idp)
  end

  let!(:raw_ed_sp) do
    create(:raw_entity_descriptor_sp)
  end

  let!(:sp_sso_descriptor) do
    create(:sp_sso_descriptor, entity_descriptor: service_provider)
  end

  before do
    request.env['HTTP_X509_DN'] = "CN=#{api_subject.x509_cn}".dup if api_subject
  end

  subject { response }

  describe 'get :index' do
    before { get :index, format: :json }

    it { is_expected.to have_http_status(:ok) }
    it { is_expected.to render_template('api/discovery_entities/index') }

    it 'assigns the identity providers' do
      expect(assigns[:identity_provider_entities])
        .to include(identity_provider)
        .and include(raw_ed_idp)
        .and not_include(service_provider)
        .and not_include(raw_ed_sp)
    end

    context 'for a disabled identity provider' do
      let!(:identity_provider) { create(:entity_descriptor, enabled: false) }

      it 'excludes the identity provider' do
        expect(assigns[:identity_provider_entities])
          .not_to include(identity_provider)
      end
    end

    context 'for a disabled raw entity descriptor - idp' do
      let!(:raw_ed_idp) do
        create(:raw_entity_descriptor_idp, enabled: false)
      end

      it 'excludes the identity provider' do
        expect(assigns[:identity_provider_entities])
          .not_to include(raw_ed_idp)
      end
    end

    it 'assigns the service providers' do
      expect(assigns[:service_provider_entities])
        .to include(service_provider)
        .and include(raw_ed_sp)
        .and not_include(identity_provider)
        .and not_include(raw_ed_idp)
    end

    context 'for a disabled service provider' do
      let!(:service_provider) { create(:entity_descriptor, enabled: false) }

      it 'excludes the service provider' do
        expect(assigns[:service_provider_entities])
          .not_to include(service_provider)
      end
    end

    context 'for a disabled raw entity descriptor - sp' do
      let!(:raw_ed_sp) do
        create(:raw_entity_descriptor_sp, enabled: false)
      end

      it 'excludes the service provider' do
        expect(assigns[:service_provider_entities])
          .not_to include(raw_ed_sp)
      end
    end

    context 'with no permissions' do
      let(:api_subject) { create(:api_subject) }

      it { is_expected.to have_http_status(:ok) }
      it { is_expected.to render_template('api/discovery_entities/index') }
    end

    context 'when unauthenticated' do
      let(:api_subject) { nil }

      it { is_expected.to have_http_status(:ok) }
      it { is_expected.to render_template('api/discovery_entities/index') }
    end
  end
end
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe API::Edugain::ServiceProviderExportsController, type: :request do
  let(:entity_descriptor) { create(:entity_descriptor, :with_sp) }
  let(:entity_id) { entity_descriptor.entity_id.uri }
  before { create :mdui_ui_info, role_descriptor: entity_descriptor.sp_sso_descriptors.first }

  let(:api_subject) { create(:api_subject, :token, :authorized) }

  describe 'POST /api/edugain/service_provider_exports' do
    subject(:run) do
      post '/api/edugain/service_provider_exports',
           params: { entity_id: entity_id, information_url: 'https://google.co.nz' },
           headers: { Authorization: +"Bearer #{api_subject.token}" }
    end

    it 'tags the KnownEntity as aaf-edugain-export' do
      expect(entity_descriptor.known_entity.tags.map(&:name)).not_to include 'aaf-edugain-export'

      run
      entity_descriptor.reload

      expect(entity_descriptor.known_entity.tags.map(&:name)).to include 'aaf-edugain-export'
    end

    it 'adds attributes for Edugain' do
      expect(entity_descriptor.entity_attribute?).to be false

      run
      entity_descriptor.reload

      attributes = entity_descriptor.entity_attribute.attributes
      expect(attributes.map(&:name))
        .to contain_exactly 'http://macedir.org/entity-category',
                            'urn:oasis:names:tc:SAML:attribute:assurance-certification'
      expect(attributes.map(&:name_format).map(&:uri))
        .to contain_exactly 'urn:oasis:names:tc:SAML:2.0:attrname-format:uri',
                            'urn:oasis:names:tc:SAML:2.0:attrname-format:uri'
      expect(attributes.flat_map(&:attribute_values).map(&:value))
        .to contain_exactly 'http://refeds.org/category/research-and-scholarship',
                            'https://refeds.org/sirtfi'
    end

    it 'adds an InformationUrl' do
      expect(entity_descriptor.sp_sso_descriptors.first.ui_info.information_urls).to be_empty

      run
      entity_descriptor.reload

      expect(entity_descriptor.sp_sso_descriptors.first.ui_info.information_urls.first)
        .to have_attributes uri: 'https://google.co.nz', lang: 'en'
    end
  end
end

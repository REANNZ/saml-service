# frozen_string_literal: true

require 'rails_helper'

RSpec.describe API::Edugain::IdentityProviderExportsController, type: :request do
  let(:entity_descriptor) { create(:entity_descriptor, :with_idp) }
  let(:entity_id) { entity_descriptor.entity_id.uri }

  let(:api_subject) { create(:api_subject, :token, :authorized) }

  describe 'POST /api/edugain/identity_provider_exports' do
    subject(:run) do
      post '/api/edugain/identity_provider_exports',
           params: { entity_id: entity_id },
           headers: { Authorization: +"Bearer #{api_subject.token}" }
    end

    it 'tags the KnownEntity as aaf-edugain-verified' do
      expect(entity_descriptor.known_entity.tags).to be_empty

      run
      entity_descriptor.reload

      expect(entity_descriptor.known_entity.tags.first.name).to eq 'aaf-edugain-export'
    end

    it 'adds attributes for Edugain' do
      expect(entity_descriptor.entity_attribute?).to be false

      run
      entity_descriptor.reload

      attributes = entity_descriptor.entity_attribute.attributes
      expect(attributes.map(&:name))
        .to contain_exactly 'http://macedir.org/entity-category-support',
                            'urn:oasis:names:tc:SAML:attribute:assurance-certification'
      expect(attributes.map(&:name_format).map(&:uri))
        .to contain_exactly 'urn:oasis:names:tc:SAML:2.0:attrname-format:uri',
                            'urn:oasis:names:tc:SAML:2.0:attrname-format:uri'
      expect(attributes.flat_map(&:attribute_values).map(&:value))
        .to contain_exactly 'http://refeds.org/category/research-and-scholarship',
                            'https://refeds.org/sirtfi'
    end
  end
end

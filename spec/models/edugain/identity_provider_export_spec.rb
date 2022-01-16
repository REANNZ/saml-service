# frozen_string_literal: true

require 'rails_helper'

describe Edugain::IdentityProviderExport do
  describe '#save' do
    subject(:save) { described_class.new(entity_id: entity_id).save }

    context 'with an extant entity' do
      let(:entity_descriptor) { create(:entity_descriptor, :with_idp) }
      let(:entity_id) { entity_descriptor.entity_id.uri }

      it 'tags the KnownEntity as aaf-edugain-verified' do
        expect(entity_descriptor.known_entity.tags).to be_empty

        save
        entity_descriptor.reload

        expect(entity_descriptor.known_entity.tags.first.name).to eq 'aaf-edugain-export'
      end

      it 'adds attributes for Edugain' do
        expect(entity_descriptor.entity_attribute?).to be false

        save
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

      context 'without an EntityAttribute' do
        it 'creates an EntityAttribute' do
          expect { save }.to change { MDATTR::EntityAttribute.count }.by 1
        end
      end

      context 'with an EntityAttribute' do
        let!(:entity_attribute) do
          MDATTR::EntityAttribute.create(entity_descriptor: entity_descriptor)
        end

        it 'uses that entity attribute' do
          expect { save }.not_to(change { MDATTR::EntityAttribute.count })
        end
      end
    end

    context 'with a nonexistent entity' do
      let(:entity_id) { 'foobar' }

      it 'raises Sequel::NoMatchingRow' do
        expect { save }.to raise_error Sequel::NoMatchingRow
      end
    end
  end
end

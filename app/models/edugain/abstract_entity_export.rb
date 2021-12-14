# frozen_string_literal: true

module Edugain
  class AbstractEntityExport
    attr_reader :entity_id

    def initialize(entity_id:)
      @entity_id = entity_id
    end

    def save
      add_research_and_scholarship
      add_sirtfi
      entity_descriptor.known_entity.tag_as EdugainHelper::edugain_export_tag
      entity_descriptor.known_entity.touch
      entity_descriptor.save raise_on_save_failure: true
    end

    private

    def add_research_and_scholarship
      attr = Attribute.create name: research_and_scholarship_attribute_name,
                              entity_attribute: entity_attribute
      NameFormat.create uri: 'urn:oasis:names:tc:SAML:2.0:attrname-format:uri',
                        attribute: attr
      AttributeValue.create value: 'http://refeds.org/category/research-and-scholarship',
                            attribute: attr
    end

    def add_sirtfi
      attr = Attribute.create name: 'urn:oasis:names:tc:SAML:attribute:assurance-certification',
                              entity_attribute: entity_attribute
      NameFormat.create uri: 'urn:oasis:names:tc:SAML:2.0:attrname-format:uri',
                        attribute: attr
      AttributeValue.create value: 'https://refeds.org/sirtfi',
                            attribute: attr
    end

    def entity_descriptor
      @entity_descriptor ||= entity_id_record.entity_descriptor
    end

    def entity_attribute
      @entity_attribute ||=
        entity_descriptor.entity_attribute ||
        MDATTR::EntityAttribute.create(entity_descriptor: entity_descriptor)
    end

    def entity_id_record
      @entity_id_record ||= EntityId[uri: entity_id].tap do |eid|
        raise ArgumentError, 'Could not find an entry for supplied entity_id' if eid.nil?
      end
    end
  end
end

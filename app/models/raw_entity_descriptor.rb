# frozen_string_literal: true

require 'ostruct'
require 'metadata/schema'

class RawEntityDescriptor < Sequel::Model
  include Metadata::Schema
  include RawEntityDescriptorDeconstructor

  many_to_one :known_entity

  one_to_one :entity_id

  plugin :association_dependencies, entity_id: :destroy

  alias idp? idp
  alias sp? sp
  alias standalone_aa? standalone_aa

  def validate
    super
    validates_presence %i[known_entity xml created_at updated_at]
    validates_presence :entity_id, allow_missing: new?
    # Any more than 16_777_215, the column type needs to be upgraded (again).
    validates_max_length 16_777_215, :xml

    # The two remaining validations are very expensive and don't need to run
    # when calling `functioning?` on an unmodified record.
    return unless modified?

    validates_unique :known_entity # Prevented by DB schema
    validate_xml
  end

  def functioning?
    valid? && enabled
  end

  def validate_xml
    return if xml.blank?

    doc = Nokogiri::XML.parse(xml)
    validate_document_contents(doc)

    return if metadata_schema.valid?(doc)

    errors.add(:xml, 'is not valid per the XML Schema')
  end

  def validate_document_contents(doc)
    errors.add(:xml, 'must have <EntityDescriptor> as the root') unless doc.root.name == 'EntityDescriptor'

    ns = doc.root.namespace.try(:href)
    return if ns == 'urn:oasis:names:tc:SAML:2.0:metadata'

    errors.add(:xml, 'must have SAML 2.0 metadata namespace on root element')
  end
end

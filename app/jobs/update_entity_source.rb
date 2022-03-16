# frozen_string_literal: true

require 'metadata/schema'
require 'net/http'

class UpdateEntitySource
  include SetSamlTypeFromXml
  include Metadata::Schema

  def self.perform(id:)
    new.perform(id: id)
  end

  def perform(id:)
    source = EntitySource[id]
    raise("Unable to locate EntitySource(id=#{id})") unless source

    untouched = KnownEntity.where(entity_source: source).select_map(:id)

    document(source).xpath(ENTITY_DESCRIPTOR_XPATH).each do |node|
      Sequel::Model.db.transaction do
        process_entity_descriptor(source, node, untouched)
      end
    end

    Sequel::Model.db.transaction { sweep(untouched) }
    true
  end

  private

  def process_entity_descriptor(source, node, untouched)
    # We represent each EntityDescriptor as a standalone piece of XML in the
    # database for future processing.
    #
    # This approach (creating new document) reduces C14N calculation per
    # EntityDescriptor by ~99.3%
    partial_document = Nokogiri::XML::Document.new
    partial_document.root = node
    ke = known_entity(source, partial_document.root)

    update_raw_entity_descriptor(ke, partial_document.root)

    # Changes updated_at timestamp for associated KnownEntity
    # which is used by MDQP for etag generation / caching.
    ke.touch

    untouched.delete(ke.id)
  end

  def retrieve(source)
    url = URI.parse(source.url)
    response = perform_http_client_request(url)

    return response.body if response.is_a?(Net::HTTPSuccess)

    pe = "Unable to update EntitySource(id=#{source.id} url=#{source.url})."
    se = "Response was: #{response.code} #{response.message}"
    raise(error_message(pe, se))
  end

  def perform_http_client_request(url)
    request = Net::HTTP::Get.new(url)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = (url.scheme == 'https')
    http.read_timeout = 600

    http.request(request)
  end

  def document(source)
    doc = Nokogiri::XML.parse(retrieve(source))

    errors = metadata_schema.validate(doc)
    if errors.empty?
      verify_signature(source, doc)
      return doc_using_saml_metadata_as_default_ns(doc)
    end

    pe = "Unable to update EntitySource(id=#{source.id} url=#{source.url})."
    raise(error_message(pe, errors.join(', ')))
  end

  def doc_using_saml_metadata_as_default_ns(doc)
    saml_md_uri = 'urn:oasis:names:tc:SAML:2.0:metadata'
    root = doc.root

    # We work to: <.. xmlns='urn:oasis:names:tc:SAML:2.0:metadata' ...>
    # Not: <.. xmlns:md='urn:oasis:names:tc:SAML:2.0:metadata' ...>
    # The latter format being used by at least eduGAIN and possibly elsewhere.
    return doc if root.namespaces.key(saml_md_uri) == 'xmlns'

    # This has to be done manually due to limitiations
    # within Nokogiri namespace manipulation functionality.
    prev_prefix = doc.root.namespace.prefix
    doc.root.default_namespace = saml_md_uri
    new_doc_markup = doc.canonicalize.gsub(%r{([<|/])(#{prev_prefix}:)}, '\1')

    Nokogiri::XML.parse(new_doc_markup)
  end

  def verify_signature(source, doc)
    return if Xmldsig::SignedDocument.new(doc).validate(source.x509_certificate)

    pe = "Signature invalid on EntitySource(id=#{source.id} url=#{source.url})."
    raise(error_message(pe))
  end

  def known_entity(source, root_node)
    ke = known_entity_within_entity_source(source, root_node)
    return ke if ke.present?

    ke = KnownEntity.create(entity_source: source, enabled: true)
    ke.tag_as(source.source_tag)
    ke
  end

  def update_raw_entity_descriptor(entity, root_node)
    raw_xml = root_node.canonicalize
    if entity.raw_entity_descriptor
      entity.raw_entity_descriptor.update(xml: raw_xml)
    else
      red = RawEntityDescriptor.create(known_entity: entity,
                                       xml: raw_xml, enabled: true)
      EntityId.create(uri: root_node['entityID'], raw_entity_descriptor: red)
    end

    set_saml_type(entity.raw_entity_descriptor, root_node)
  end

  def sweep(untouched)
    KnownEntity.where(id: untouched).each do |ke|
      ke.try(:raw_entity_descriptor).try(:entity_id).try(:destroy)
      ke.try(:raw_entity_descriptor).try(:destroy)
      ke.destroy
    end
  end

  def known_entity_within_entity_source(source, root_node)
    entity_id = EntityId.where(uri: root_node['entityID']).all.find do |eid|
      eid.parent.known_entity.entity_source == source
    end
    entity_id&.parent&.known_entity
  end

  def error_message(primary_error, secondary_error = nil)
    return primary_error unless secondary_error

    "#{primary_error}\n#{secondary_error}"
  end
end

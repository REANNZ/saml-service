# frozen_string_literal: true

require 'metadata/saml'
require 'metadata/schema_invalid_error'

class MetadataQueryController < ApplicationController
  SAML_CONTENT_TYPE = 'application/samlmetadata+xml'
  SHA1_REGEX = /{sha1}(.*)?/.freeze

  include MetadataQueryCaching

  skip_before_action :ensure_authenticated
  before_action :ensure_get_request, :ensure_content_type,
                :ensure_accept_charset, :ensure_metadata_instance

  def all_entities
    public_action

    return not_found unless @metadata_instance.all_entities

    tags = [@metadata_instance.primary_tag]
    handle_entities_request(tags)
  end

  def tagged_entities
    public_action

    tags = [@metadata_instance.primary_tag, params[:identifier]]
    handle_entities_request(tags)
  end

  def specific_entity
    public_action

    handle_entity_request(EntityId.first(uri: params[:identifier]))
  end

  def specific_entity_sha1
    public_action

    sha1_identifier = params[:identifier].match(SHA1_REGEX)
    handle_entity_request(EntityId.first(sha1: sha1_identifier[1]))
  end

  private

  def handle_entities_request(tags)
    Sequel::Model.db.transaction(isolation: :repeatable) do
      known_entities = KnownEntity.with_all_tags(tags)
      return not_found if known_entities.blank?

      etag = generate_document_entities_etag(@metadata_instance, known_entities)
      if known_entities_unmodified?(known_entities, etag)
        return head :not_modified
      end

      create_known_entities_response(known_entities, etag)
    end
  end

  def handle_entity_request(entity_id)
    return not_found unless entity_id

    Sequel::Model.db.transaction(isolation: :repeatable) do
      known_entity = entity_id.parent.known_entity
      etag = generate_document_entities_etag(@metadata_instance, [known_entity])
      return head :not_modified if known_entity_unmodified?(known_entity, etag)

      create_known_entity_response(known_entity, etag)
    end
  end

  def ensure_get_request
    return if request.get?

    head :method_not_allowed
    false
  end

  def ensure_content_type
    return if request.accept == MetadataQueryController::SAML_CONTENT_TYPE

    head :not_acceptable
    false
  end

  def ensure_accept_charset
    return if !request.accept_charset || request.accept_charset == 'utf-8'

    head :not_acceptable
    false
  end

  def ensure_metadata_instance
    @metadata_instance = MetadataInstance[identifier: params[:instance]]

    if @metadata_instance
      @saml_renderer = Metadata::SAML.new(metadata_instance: @metadata_instance)
      return
    end

    not_found
    false
  end

  def create_headers(obj, etag)
    response.headers['ETag'] = etag
    response.headers['Last-Modified'] = obj.updated_at.rfc2822
    response.headers['Content-Type'] =
      "#{MetadataQueryController::SAML_CONTENT_TYPE}; charset=utf-8"

    expires_in @metadata_instance.cache_period
  end

  def create_known_entity_response(known_entity, etag)
    response = cache_descriptor_response(known_entity, etag)

    create_headers(known_entity, etag)
    render body: response[:metadata]
  end

  def create_known_entities_response(known_entities, etag)
    response = cache_known_entities_response(known_entities, etag)

    create_headers(known_entities.max_by(&:updated_at), etag)
    render body: response[:metadata]
  end

  def not_found
    ttl = Rails.application.config.saml_service.metadata.negative_cache_ttl
    expires_in(ttl)

    head :not_found
  end
end

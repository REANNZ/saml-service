# frozen_string_literal: true

json.ignore_nil!

def insert_localized_url(json, obj)
  json.url obj.uri
  json.lang obj.lang
end

def insert_logo(json, obj)
  json.url obj.uri
  json.lang obj.lang
  json.width obj.width
  json.height obj.height
end

def insert_ui_info(json, ui_info)
  display_names = ui_info.try(:display_names) || []
  json.names(display_names, :value, :lang)

  logos = ui_info.try(:logos) || []
  json.logos(logos) { |logo| insert_logo(json, logo) }

  descriptions = ui_info.try(:descriptions) || []
  json.descriptions(descriptions, :value, :lang)
end

def insert_tags(json, entity)
  tags = entity.known_entity.tags.map(&:name)
  json.tags(tags.uniq)
end

# rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity

def insert_discovery_response_endpoints(json, obj)
  dre =
    (obj.try(:sp_sso_descriptors).try(:first)
       .try(:discovery_response_services) ||
    obj.try(:discovery_response_services) ||
    []).sort_by(&:index)

  default_endpoint = (dre.find(&:is_default) || dre.find do |dr|
                        dr.is_default.nil?
                      end || dre.first)&.location
  json.discovery_response(default_endpoint)
  json.all_discovery_response_endpoints(dre.map(&:location))
end
# rubocop:enable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity

def insert_single_sign_on_endpoints(json, obj)
  json.single_sign_on_endpoints do
    insert_single_sign_on_soap_endpoints(json, obj)
  end
end

def insert_single_sign_on_soap_endpoints(json, obj)
  se =
    obj.try(:idp_sso_descriptors).try(:first)
       .try(:single_sign_on_services) ||
    obj.try(:single_sign_on_services) ||
    []

  sso_soap_endpoints =
    se.select { |e| e.binding == 'urn:oasis:names:tc:SAML:2.0:bindings:SOAP' }
      .sort_by(&:id).map(&:location)

  json.soap(sso_soap_endpoints)
end

json.identity_providers(@identity_provider_entities) do |obj|
  ui_info =
    obj.try(:idp_sso_descriptors).try(:first).try(:ui_info) ||
    obj.try(:ui_info) ||
    []

  disco_hints =
    obj.try(:idp_sso_descriptors).try(:first).try(:disco_hints) ||
    obj.try(:disco_hints) || []

  json.entity_id(obj.entity_id.uri)

  insert_tags(json, obj)
  insert_ui_info(json, ui_info)
  insert_single_sign_on_endpoints(json, obj)

  geolocations = disco_hints.try(:geolocation_hints) || []
  json.geolocations(geolocations, :latitude, :longitude, :altitude)

  domains = disco_hints.try(:domain_hints) || []
  json.domains(domains.map(&:domain))
end

json.service_providers(@service_provider_entities) do |obj|
  ui_info =
    obj.try(:sp_sso_descriptors).try(:first).try(:ui_info) ||
    obj.try(:ui_info) ||
    []

  json.entity_id(obj.entity_id.uri)

  insert_tags(json, obj)
  insert_ui_info(json, ui_info)
  insert_discovery_response_endpoints(json, obj)

  information_urls = ui_info.try(:information_urls) || []
  json.information_urls(information_urls) { |o| insert_localized_url(json, o) }

  privacy_statement_urls = ui_info.try(:privacy_statement_urls) || []
  json.privacy_statement_urls(privacy_statement_urls) do |o|
    insert_localized_url(json, o)
  end
end

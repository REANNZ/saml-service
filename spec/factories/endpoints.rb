# frozen_string_literal: true

FactoryBot.define do
  trait :endpoint do
    binding { "urn:oasis:names:tc:SAML:2.0:bindings:#{Faker::Lorem.word}" }
    location { Faker::Internet.url host: 'example.com' }
  end

  trait :response_location do
    response_location { Faker::Internet.url host: 'example.com' }
  end

  trait :indexed_endpoint do
    endpoint
    is_default { false }
    index { Faker::Base.numerify '#' }
  end

  trait :default_indexed_endpoint do
    indexed_endpoint
    is_default { true }
  end

  factory :_endpoint, class: 'Endpoint', traits: [:endpoint]
  factory :_indexed_endpoint, class: 'IndexedEndpoint',
                              traits: [:indexed_endpoint]

  # SSODescriptor
  factory :artifact_resolution_service do
    indexed_endpoint
    sso_descriptor
  end

  factory :single_logout_service do
    endpoint
    sso_descriptor
  end

  factory :manage_name_id_service do
    endpoint
    sso_descriptor
  end

  # IDPSSODescriptor
  factory :single_sign_on_service do
    endpoint
    idp_sso_descriptor
  end

  factory :name_id_mapping_service do
    endpoint
    idp_sso_descriptor
  end

  # AttributeAuthorityDescriptor
  factory :attribute_service do
    endpoint
    association :attribute_authority_descriptor
  end

  # IDPSSODescriptor or AttributeAuthorityDescriptor
  factory :assertion_id_request_service, traits: [:endpoint]

  # SPSSODescritpor
  factory :assertion_consumer_service do
    indexed_endpoint
    sp_sso_descriptor
  end

  factory :discovery_response_service do
    binding { 'urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol' }
    indexed_endpoint
    sp_sso_descriptor
  end
end

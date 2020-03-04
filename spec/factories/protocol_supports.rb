# frozen_string_literal: true

FactoryBot.define do
  factory :protocol_support do
    uri { 'urn:oasis:names:tc:SAML:2.0:protocol' }
    association :role_descriptor
  end
end

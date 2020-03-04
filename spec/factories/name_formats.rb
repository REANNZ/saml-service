# frozen_string_literal: true

FactoryBot.define do
  factory :name_format do
    uri { 'urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified' }
    association :attribute

    trait :uri do
      uri { 'urn:oasis:names:tc:SAML:2.0:attrname-format:uri' }
    end
  end
end

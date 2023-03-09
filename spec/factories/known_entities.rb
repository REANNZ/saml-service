# frozen_string_literal: true

FactoryBot.define do
  factory :known_entity do
    transient do
      hostname { "e.#{Faker::Internet.domain_name}" }
    end

    association :entity_source
    enabled { true }

    trait :with_idp do
      after(:create) do |ke|
        idp = create :idp_sso_descriptor
        ke.entity_descriptor = idp.entity_descriptor
      end
    end

    trait :with_raw_entity_descriptor do
      after(:create) do |ke|
        red = create :raw_entity_descriptor, known_entity: ke
        ke.raw_entity_descriptor = red
      end
    end

    after(:create) do |ke|
      ke.tag_as(ke.entity_source.source_tag)
    end
  end
end

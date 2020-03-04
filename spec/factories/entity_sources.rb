# frozen_string_literal: true

FactoryBot.define do
  factory :entity_source do
    enabled { true }
    # Max BIGINT value + 1, according to MySQL documentation
    rank { rand(9_223_372_036_854_775_808) }
    sequence(:source_tag) { |n| "#{Faker::Lorem.characters(number: 20)}-#{n}" }

    trait :external do
      url { "https://#{Faker::Internet.domain_name}/federation/metadata.xml" }
    end
  end
end

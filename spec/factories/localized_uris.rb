# frozen_string_literal: true

FactoryBot.define do
  factory :localized_uri do
    uri { Faker::Internet.url }
    lang { 'en' }
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :localized_name do
    value { Faker::Lorem.sentence }
    lang { 'en' }
  end
end

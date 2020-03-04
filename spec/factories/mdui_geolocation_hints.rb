# frozen_string_literal: true

FactoryBot.define do
  factory :mdui_geolocation_hint, class: 'MDUI::GeolocationHint' do
    transient { components { 2 } }

    uri do
      "geo:#{(1..components).map { Faker::Number.number(digits: 3) }.join(',')}"
    end
    association :disco_hints, factory: :mdui_disco_hint

    trait :with_altitude do
      transient { components { 3 } }
    end
  end
end

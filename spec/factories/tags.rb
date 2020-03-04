# frozen_string_literal: true

FactoryBot.define do
  factory :tag do
    sequence :name do |n|
      "#{Faker::Lorem.characters(number: 20)}-#{n}"
    end
    association :known_entity
  end

  factory :known_entity_tag, class: 'Tag' do
    sequence(:name) { |n| "#{Faker::Lorem.characters(number: 20)}-#{n}" }
    association :known_entity
  end
end

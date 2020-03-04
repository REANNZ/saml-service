# frozen_string_literal: true

FactoryBot.define do
  factory :key_descriptor do
    disabled { false }

    after :create do |kd|
      create :key_info, key_descriptor: kd
    end

    trait :signing do
      key_type { :signing }
    end

    trait :encryption do
      key_type { :encryption }
    end
  end
end

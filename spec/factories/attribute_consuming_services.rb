# frozen_string_literal: true

FactoryBot.define do
  factory :attribute_consuming_service do
    index { Faker::Number.number digits: 2 }
    default { false }
    sp_sso_descriptor

    after(:create) do |acs|
      acs.add_service_name create :service_name,
                                  attribute_consuming_service: acs
      acs.add_service_description create :service_description,
                                         attribute_consuming_service: acs
      acs.add_requested_attribute create :requested_attribute,
                                         attribute_consuming_service: acs
    end

    trait :with_multiple_service_names do
      after(:create) do |acs|
        create_list(:service_name, 2, attribute_consuming_service: acs)
      end
    end

    trait :with_multiple_service_descriptions do
      after(:create) do |acs|
        create_list(:service_description, 2, attribute_consuming_service: acs)
      end
    end

    trait :with_multiple_requested_attributes do
      after(:create) do |acs|
        create_list(:requested_attribute, 2, attribute_consuming_service: acs)
      end
    end
  end
end

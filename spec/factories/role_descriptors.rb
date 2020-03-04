# frozen_string_literal: true

FactoryBot.define do
  factory :role_descriptor do
    entity_descriptor
    enabled { true }

    after(:create) do |rd|
      rd.add_protocol_support(create(:protocol_support, role_descriptor: rd))
      rd.add_protocol_support(create(:protocol_support, role_descriptor: rd))
    end

    trait :with_error_url do
      error_url { Faker::Internet.url }
    end

    trait :with_disabled_key_descriptor do
      after(:create) do |rd|
        create(:key_descriptor, :encryption, disabled: true,
                                             role_descriptor: rd)
      end
    end

    trait :with_key_descriptors do
      after(:create) do |rd|
        create_list(:key_descriptor, 2, role_descriptor: rd)
      end
    end

    trait :with_extensions do
      extensions { "<some-node>#{Faker::Lorem.paragraph}</some-node>" }
    end

    trait :with_organization do
      after(:create) do |rd|
        rd.organization = create :organization
      end
    end

    trait :with_contacts do
      after(:create) do |rd|
        create_list(:contact_person, 2, role_descriptor: rd)
      end
    end

    trait :with_scope do
      after(:create) do |rd|
        create(:shibmd_scope, role_descriptor: rd)
      end
    end

    trait :with_scopes do
      after(:create) do |rd|
        create_list(:shibmd_scope, 2, role_descriptor: rd)
      end
    end

    trait :with_ui_info do
      after(:create) do |rd|
        rd.ui_info = create :mdui_ui_info, :with_content, role_descriptor: rd
      end
    end
  end
end

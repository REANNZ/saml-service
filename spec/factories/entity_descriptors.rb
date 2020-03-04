# frozen_string_literal: true

FactoryBot.define do
  factory :entity_descriptor do
    enabled { true }

    association :known_entity
    association :organization

    after :create do |ed|
      ed.entity_id = create :entity_id, entity_descriptor: ed
      ed.registration_info = create :mdrpi_registration_info
    end

    trait :with_technical_contact do
      after :create do |ed|
        ed.add_contact_person create :contact_person, entity_descriptor: ed
      end
    end

    trait :with_publication_info do
      after(:create) do |ed|
        ed.publication_info = create :mdrpi_publication_info
      end
    end

    trait :with_entity_attribute do
      after(:create) do |ed|
        ed.entity_attribute = create :mdattr_entity_attribute
      end
    end

    trait :with_refeds_rs_entity_category do
      after(:create) do |ed|
        ed.entity_attribute = create :mdattr_entity_attribute,
                                     :with_refeds_rs_entity_category
      end
    end

    trait :with_idp do
      after :create do |ed|
        ed.add_idp_sso_descriptor create :idp_sso_descriptor,
                                         entity_descriptor: ed
      end
    end

    trait :with_sp do
      after :create do |ed|
        ed.add_sp_sso_descriptor create :sp_sso_descriptor,
                                        entity_descriptor: ed
      end
    end

    trait :with_aa do
      after :create do |ed|
        ed.add_attribute_authority_descriptor(
          create(:attribute_authority_descriptor, entity_descriptor: ed)
        )
      end
    end

    trait :with_sirtfi_contact do
      after :create do |ed|
        ed.add_sirtfi_contact_person create :sirtfi_contact_person,
                                            entity_descriptor: ed
      end
    end
  end
end

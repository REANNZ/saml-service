# frozen_string_literal: true

FactoryBot.define do
  factory :metadata_instance do
    association :keypair

    name { Faker::Internet.domain_name }

    hash_algorithm { 'sha256' }
    validity_period { 1.hour }
    cache_period { 6.hours }
    federation_identifier { Faker::Lorem.word }

    primary_tag { SecureRandom.urlsafe_base64(16) }
    identifier { SecureRandom.urlsafe_base64(16) }
    all_entities { true }

    after :create do |mi|
      create(:mdrpi_publication_info, metadata_instance: mi)
      mi.reload
    end

    trait :with_registration_info do
      after :create do |mi|
        mi.registration_info = create :mdrpi_registration_info
      end
    end
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :api_subject, class: 'API::APISubject' do
    description { Faker::Lorem.sentence }
    contact_name { Faker::Name.name }
    contact_mail { Faker::Internet.email }
    enabled { true }

    trait :authorized do
      transient { permission { '*' } }

      after(:create) do |api_subject, attrs|
        role = create :role
        permission = create :permission, value: attrs.permission
        role.add_permission permission
        role.add_api_subject api_subject
      end
    end

    trait :x509_cn do
      x509_cn { Faker::Lorem.word }
    end

    trait :token do
      token { Faker::Alphanumeric.alpha(number: 10) }
    end
  end
end

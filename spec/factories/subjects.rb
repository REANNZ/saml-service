# frozen_string_literal: true

FactoryBot.define do
  factory :subject do
    name { Faker::Name.name }
    mail { Faker::Internet.email }
    enabled { true }
    complete { true }

    shared_token { SecureRandom.urlsafe_base64(16) }
    targeted_id do
      "https://rapid.example.com!https://ide.example.com!#{SecureRandom.hex}"
    end

    trait :authorized do
      transient { permission { '*' } }

      after(:create) do |subject, attrs|
        role = create :role
        permission = create :permission, value: attrs.permission, role: role
        role.add_permission(permission)
        role.add_subject(subject)
      end
    end
  end
end

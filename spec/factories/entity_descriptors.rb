FactoryGirl.define do
  factory :entity_descriptor do
    association :entities_descriptor

    after :create do |ed|
      ed.entity_id = create :entity_id, entity_descriptor: ed
    end

    trait :with_publication_info do
      after(:create) do | ed |
        ed.publication_info = create :mdrpi_publication_info, :with_usage_policy
      end
    end

    trait :with_registration_info do
      after(:create) do | ed |
        ed.registration_info = create :mdrpi_registration_info, :with_policy
      end
    end
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :sp_sso_descriptor, parent: :sso_descriptor,
                              class: 'SPSSODescriptor' do
    authn_requests_signed { false }
    want_assertions_signed { false }

    after(:create) do |sp|
      sp.add_assertion_consumer_service(create(:assertion_consumer_service,
                                               sp_sso_descriptor: sp))
    end

    trait :with_key_descriptors do
      after(:create) do |sp|
        create_list(:key_descriptor, 2, :signing, role_descriptor: sp)
      end
    end

    trait :with_disabled_key_descriptor do
      after(:create) do |sp|
        create(:key_descriptor, :encryption, disabled: true,
                                             role_descriptor: sp)
      end
    end

    trait :with_single_logout_services do
      after(:create) do |sp|
        create_list(:single_logout_service, 2, sso_descriptor: sp)
      end
    end

    trait :with_manage_name_id_services do
      after(:create) do |sp|
        create_list(:manage_name_id_service, 2, sso_descriptor: sp)
      end
    end

    trait :with_name_id_formats do
      after(:create) do |sp|
        create_list(:name_id_format, 2, sso_descriptor: sp)
      end
    end

    trait :with_artifact_resolution_services do
      after(:create) do |idp|
        create_list(:artifact_resolution_service, 2, sso_descriptor: idp)
      end
    end

    trait :with_authn_requests_signed do
      authn_requests_signed { true }
    end

    trait :with_want_assertions_signed do
      want_assertions_signed { true }
    end

    trait :with_multiple_assertion_consumer_services do
      after(:create) do |sp|
        create_list(:assertion_consumer_service, 2, sp_sso_descriptor: sp)
      end
    end

    trait :request_attributes do
      after(:create) do |sp|
        sp.add_attribute_consuming_service(create(:attribute_consuming_service,
                                                  sp_sso_descriptor: sp))
      end
    end

    trait :with_attribute_consuming_services do
      after(:create) do |sp|
        create_list(:attribute_consuming_service, 2, sp_sso_descriptor: sp)
      end
    end

    trait :with_ui_info do
      after(:create) do |sp|
        sp.ui_info = create :mdui_ui_info, :with_content, role_descriptor: sp
      end
    end

    trait :with_discovery_response_services do
      after(:create) do |sp|
        create(:discovery_response_service, sp_sso_descriptor: sp)
      end
    end
  end
end

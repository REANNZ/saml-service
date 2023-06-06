# frozen_string_literal: true

FactoryBot.define do
  factory :mdui_ui_info, class: 'MDUI::UIInfo' do
    role_descriptor

    after(:create) do |ui_info|
      ui_info.add_display_name create(:mdui_display_name, ui_info:)
      ui_info.add_description create(:mdui_description, ui_info:)
    end

    trait :with_multiple_display_names do
      after(:create) do |ui_info|
        ui_info.add_display_name create(:mdui_display_name, ui_info:)
      end
    end

    trait :with_multiple_descriptions do
      after(:create) do |ui_info|
        ui_info.add_description create(:mdui_description, ui_info:)
      end
    end

    trait :with_content do
      after(:create) do |ui_info|
        ui_info.add_keyword_list create(:mdui_keyword_list_with_content,
                                        ui_info:)
        ui_info.add_logo create(:mdui_logo, ui_info:)
        ui_info.add_information_url create(:mdui_information_url,
                                           ui_info:)
        ui_info.add_privacy_statement_url create(:mdui_privacy_statement_url,
                                                 ui_info:)
      end
    end
  end
end

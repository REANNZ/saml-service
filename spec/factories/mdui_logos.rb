# frozen_string_literal: true

FactoryBot.define do
  factory :mdui_logo, class: 'MDUI::Logo', parent: :localized_uri do
    width { Faker::Number.number(digits: 3).to_i + 1 }
    height { Faker::Number.number(digits: 3).to_i + 2 }
    association :ui_info, factory: :mdui_ui_info
  end
end

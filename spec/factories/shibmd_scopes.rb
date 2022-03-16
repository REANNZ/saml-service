# frozen_string_literal: true

FactoryBot.define do
  factory :shibmd_scope, class: 'Shibmd::Scope' do
    association :role_descriptor, factory: :idp_sso_descriptor
    value { Faker::Internet.domain_name }
    regexp { false }
    locked { false }
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :mdrpi_usage_policy, class: 'MDRPI::UsagePolicy',
                               parent: :localized_uri do
    uri { 'http://www.edugain.org/policy/metadata-tou_1_0.txt' }
    publication_info factory: :mdrpi_publication_info
  end
end

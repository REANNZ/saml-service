# frozen_string_literal: true

FactoryBot.define do
  factory :encryption_method do
    key_descriptor

    algorithm { 'http://www.w3.org/2001/04/xmlenc#tripledes-cbc' }
  end
end

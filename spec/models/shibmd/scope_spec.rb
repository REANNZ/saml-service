# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Shibmd::Scope, type: :model do
  it { is_expected.to validate_presence :role_descriptor }
  it { is_expected.to validate_presence :value }
  it { is_expected.to validate_presence :regexp }
  it { is_expected.to validate_presence :created_at }
  it { is_expected.to validate_presence :updated_at }
end

require 'rails_helper'

describe OrganizationName do
  context 'Extends LocalizedName' do
    it { is_expected.to validate_presence :organization, allow_missing: false }
  end
end

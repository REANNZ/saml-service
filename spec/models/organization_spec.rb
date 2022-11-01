# frozen_string_literal: true

require 'rails_helper'

describe Organization do
  it_behaves_like 'a basic model'

  it { is_expected.to have_one_to_many :organization_names }
  it { is_expected.to have_one_to_many :organization_display_names }
  it { is_expected.to have_one_to_many :organization_urls }

  context 'validation' do
    subject { create(:organization) }

    it 'has at least 1 organization_name and url' do
      expect(subject).to validate_presence :organization_names,
                                           allow_missing: false
      expect(subject).to validate_presence :organization_display_names,
                                           allow_missing: false
      expect(subject).to validate_presence :organization_urls,
                                           allow_missing: false
    end
  end
end

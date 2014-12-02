require 'rails_helper'

RSpec.describe MDUI::Description, type: :model do
  context 'Extends LocalizedURI' do
    it { is_expected.to have_many_to_one :ui_info }
    it { is_expected.to validate_presence :ui_info }
  end
end
require 'rails_helper'

describe ManageNameIdService do
  it_behaves_like 'an Endpoint'
  it { is_expected.to have_many_to_one :sso_descriptor }
end

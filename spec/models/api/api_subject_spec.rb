# frozen_string_literal: true

require 'rails_helper'

require 'gumboot/shared_examples/api_subjects'

RSpec.describe API::APISubject, type: :model do
  it_behaves_like 'a basic model'

   subject { build :api_subject }

  it { is_expected.to be_valid }
  it { is_expected.to be_an(Accession::Principal) }
  it { is_expected.to respond_to(:roles) }
  it { is_expected.to respond_to(:permissions) }
  it { is_expected.to respond_to(:permits?) }
  it { is_expected.to respond_to(:functioning?) }

  it 'is invalid without an x509_cn' do
    subject.x509_cn = nil
    expect(subject).not_to be_valid
  end
  it 'is invalid if an x509 value is not in the correct format' do
    subject.x509_cn += '%^%&*'
    expect(subject).not_to be_valid
  end
  it 'is valid if an x509 value is in the correct format' do
    expect(subject).to be_valid
  end
  it 'is invalid if an x509 value is not unique' do
    create(:api_subject, x509_cn: subject.x509_cn)
    expect(subject).not_to be_valid
  end
  it 'is invalid without a description' do
    subject.description = nil
    expect(subject).not_to be_valid
  end
  it 'is invalid without a contact name' do
    subject.contact_name = nil
    expect(subject).not_to be_valid
  end
  it 'is invalid without a contact mail address' do
    subject.contact_mail = nil
    expect(subject).not_to be_valid
  end
  it 'is invalid without an enabled state' do
    subject.enabled = nil
    expect(subject).not_to be_valid
  end
end

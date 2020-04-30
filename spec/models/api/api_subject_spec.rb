# frozen_string_literal: true

require 'rails_helper'

require 'gumboot/shared_examples/api_subjects'

RSpec.describe API::APISubject, type: :model do
  it_behaves_like 'a basic model'

  subject { build :api_subject }

  it { is_expected.to be_an(Accession::Principal) }
  it { is_expected.to respond_to(:roles) }
  it { is_expected.to respond_to(:permissions) }
  it { is_expected.to respond_to(:permits?) }
  it { is_expected.to respond_to(:functioning?) }

  it 'is invalid without x509_cn or token' do
    expect(subject).not_to be_valid
  end

  RSpec.shared_examples 'an api_subject' do
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

  context 'with x509_cn' do
    subject { build :api_subject, :x509_cn }
    it { is_expected.to be_valid }
    include_examples 'an api_subject'

    it 'is invalid if an x509 value is not in the correct format' do
      subject.x509_cn += '%^%&*'
      expect(subject).not_to be_valid
    end
    it 'is invalid if an x509 value is not unique' do
      create(:api_subject, x509_cn: subject.x509_cn)
      expect(subject).not_to be_valid
    end
  end

  context 'with token' do
    subject { build :api_subject, :token }
    it { is_expected.to be_valid }
    include_examples 'an api_subject'

    it 'is invalid if a token value is not unique' do
      create(:api_subject, token: subject.token)
      expect(subject).not_to be_valid
    end
  end
end

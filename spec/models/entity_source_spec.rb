# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EntitySource do
  def pem_jumble(pem)
    parts = pem.split("\n").map do |s|
      next s if s.start_with?('-----', 'MII')

      s.reverse
    end

    parts.join("\n")
  end

  subject { build(:entity_source) }

  it_behaves_like 'a basic model'

  it { is_expected.to validate_presence(:rank) }
  it { is_expected.to validate_integer(:rank) }
  it { is_expected.to validate_unique(:rank) }
  it { is_expected.to validate_presence(:source_tag) }
  it { is_expected.to validate_unique(:source_tag) }
  it { is_expected.to validate_presence(:enabled) }
  it { is_expected.not_to validate_presence(:url) }
  it { is_expected.not_to validate_presence(:certificate) }

  context 'url validation' do
    it 'accepts nil, https, or http, but rejects ftp and invalid' do
      subject.url = nil
      expect(subject).to be_valid
      subject.url = 'https://fed.example.com/metadata/full.xml'
      expect(subject).to be_valid
      subject.url = 'http://fed.example.com/metadata/full.xml'
      expect(subject).to be_valid
      subject.url = 'ftp://fed.example.com/metadata/full.xml'
      expect(subject).not_to be_valid
      subject.url = 'https://fed.test example.com/metadata/full.xml'
      expect(subject).not_to be_valid
    end
  end

  context 'certificate validation' do
    it 'accepts nil or valid cert, rejects invalid' do
      subject.certificate = nil
      expect(subject).to be_valid
      subject.certificate = valid_cert
      expect(subject).to be_valid
      subject.certificate = invalid_cert
      expect(subject).not_to be_valid
      subject.certificate = 'hello!'
      expect(subject).not_to be_valid
    end
  end

  context '#x509_certificate' do
    it 'returns a certificate object or nil' do
      subject.certificate = nil
      expect(subject.x509_certificate).to be_nil
      subject.certificate = valid_cert
      expect(subject.x509_certificate).to be_an(OpenSSL::X509::Certificate)
    end
  end

  let(:valid_cert) { create(:certificate).to_pem }
  let(:invalid_cert) { pem_jumble(valid_cert) }
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FederationRegistrySource do
  let(:source) { build(:federation_registry_source) }
  subject { source }

  it_behaves_like 'a basic model'

  it { is_expected.to have_many_to_one(:entity_source) }
  it { is_expected.to validate_presence(:entity_source) }
  it { is_expected.to validate_presence(:hostname) }
  it { is_expected.to validate_presence(:secret) }
  it { is_expected.to validate_presence(:registration_authority) }
  it { is_expected.to validate_presence(:registration_policy_uri) }
  it { is_expected.to validate_presence(:registration_policy_uri_lang) }

  context 'hostname validation' do
    it 'rejects a hostname which does not parse in a url' do
      subject.hostname = 'test|example.com'
      expect(subject).not_to be_valid
    end
  end

  context 'secret validation' do
    let(:alphabet) do
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-'
    end

    it 'rejects special characters' do
      %w[! @ # $ % ^ & * ( ) + =].each do |c|
        subject.secret = "invalidsecret#{c}"
        expect(subject).not_to be_valid
      end
    end

    it 'accepts the urlsafe base64 alphabet' do
      subject.secret = alphabet.chars.shuffle.join
      expect(subject).to be_valid
    end
  end

  def url_attrs(part)
    {
      scheme: 'https',
      hostname: source.hostname,
      port: 443,
      path: "/federationregistry/export/#{part}"
    }
  end

  context '#organizations_url' do
    subject { source.organizations_url }
    it { is_expected.to have_attributes(url_attrs('organizations')) }
  end

  context '#entity_descriptors_url' do
    subject { source.entity_descriptors_url }
    it { is_expected.to have_attributes(url_attrs('entitydescriptors')) }
  end

  context '#identity_providers_url' do
    subject { source.identity_providers_url }
    it { is_expected.to have_attributes(url_attrs('identityproviders')) }
  end

  context '#service_providers_url' do
    subject { source.service_providers_url }
    it { is_expected.to have_attributes(url_attrs('serviceproviders')) }
  end

  context '#attribute_authorities_url' do
    subject { source.attribute_authorities_url }
    it { is_expected.to have_attributes(url_attrs('attributeauthorities')) }
  end
end

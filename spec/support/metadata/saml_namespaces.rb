# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_examples 'SAML namespaces' do
  context 'SAML namespaces' do
    let(:ns) { subject.ns }

    it 'works as expected' do
      is_expected.to be_a_kind_of Metadata::SamlNamespaces
      is_expected.to respond_to(:root).and(
        respond_to(:saml)
      ).and(
        respond_to(:idpdisc)
      ).and(
        respond_to(:mdrpi)
      ).and(
        respond_to(:mdui)
      ).and(
        respond_to(:mdattr)
      ).and(
        respond_to(:shibmd)
      ).and(
        respond_to(:ds)
      ).and(
        respond_to(:ns)
      ).and(
        respond_to(:fed)
      ).and(
        respond_to(:privacy)
      )
      subject.fed
      subject.privacy
      expect(subject.ns.size).to eq(12)
      expect(Metadata::SamlNamespaces::NAMESPACES.size).to eq(12)
      expect(ns).to match({
                            'xmlns' => 'urn:oasis:names:tc:SAML:2.0:metadata',
                            'xmlns:saml' => 'urn:oasis:names:tc:SAML:2.0:assertion',
                            'xmlns:idpdisc' => 'urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol',
                            'xmlns:mdrpi' => 'urn:oasis:names:tc:SAML:metadata:rpi',
                            'xmlns:mdui' => 'urn:oasis:names:tc:SAML:metadata:ui',
                            'xmlns:mdattr' => 'urn:oasis:names:tc:SAML:metadata:attribute',
                            'xmlns:shibmd' => 'urn:mace:shibboleth:metadata:1.0',
                            'xmlns:ds' => 'http://www.w3.org/2000/09/xmldsig#',
                            'xmlns:fed' => 'http://docs.oasis-open.org/wsfed/federation/200706',
                            'xmlns:privacy' => 'http://docs.oasis-open.org/wsfed/privacy/200706',
                            'xmlns:remd' => 'http://refeds.org/metadata',
                            'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance'
                          })
    end
  end
end

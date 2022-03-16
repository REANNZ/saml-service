# frozen_string_literal: true

module Metadata
  module SamlNamespaces
    NAMESPACES = {
      'xmlns' => 'urn:oasis:names:tc:SAML:2.0:metadata',
      'xmlns:saml' => 'urn:oasis:names:tc:SAML:2.0:assertion',
      'xmlns:idpdisc' =>
      'urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol',
      'xmlns:mdrpi' => 'urn:oasis:names:tc:SAML:metadata:rpi',
      'xmlns:mdui' => 'urn:oasis:names:tc:SAML:metadata:ui',
      'xmlns:mdattr' => 'urn:oasis:names:tc:SAML:metadata:attribute',
      'xmlns:shibmd' => 'urn:mace:shibboleth:metadata:1.0',
      'xmlns:ds' => 'http://www.w3.org/2000/09/xmldsig#',
      'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
      'xmlns:fed' => 'http://docs.oasis-open.org/wsfed/federation/200706',
      'xmlns:privacy' => 'http://docs.oasis-open.org/wsfed/privacy/200706',
      'xmlns:remd' => 'http://refeds.org/metadata'
    }.freeze

    def root
      builder
    end

    def saml
      builder['saml']
    end

    def idpdisc
      builder['idpdisc']
    end

    def mdrpi
      builder['mdrpi']
    end

    def mdui
      builder['mdui']
    end

    def mdattr
      builder['mdattr']
    end

    def shibmd
      builder['shibmd']
    end

    def ds
      builder['ds']
    end

    def fed
      builder['fed']
    end

    def privacy
      builder['privacy']
    end

    def ns
      NAMESPACES unless builder.doc.root
    end
  end
end

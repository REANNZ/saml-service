# frozen_string_literal: true

require 'metadata/saml_namespaces'

module Metadata
  class Saml
    include SamlNamespaces

    attr_reader :builder, :created_at, :expires_at,
                :instance_id, :metadata_instance

    protected

    # Prevent NoMethodError by defining before any usage
    def attribute_base(attr, scope)
      scope.parent[:Name] = attr.name
      scope.parent[:NameFormat] = attr.name_format.uri if attr.name_format

      scope.parent[:FriendlyName] = attr.friendly_name if attr.friendly_name.present?

      attr.attribute_values { |ds| ds.order(:value) }.each do |attr_val|
        attribute_value(attr_val)
      end
    end

    def certificate
      OpenSSL::X509::Certificate.new(metadata_instance.keypair.certificate)
    end

    def key
      OpenSSL::PKey::RSA.new(metadata_instance.keypair.key)
    end

    public

    def initialize(params)
      params.each do |k, v|
        instance_variable_set("@#{k}", v)
      end

      @builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8')
      @created_at = Time.now.utc
      @expires_at = created_at + metadata_instance.validity_period
      @instance_id = "#{metadata_instance.federation_identifier}" \
                     "#{created_at.to_formatted_s(:number)}"
    end

    def sign
      Xmldsig::SignedDocument.new(builder.doc.to_xml(indent: 2)).sign(key)
    end

    def entities_descriptor(known_entities)
      Sequel::Model.db.transaction(isolation: :repeatable) do
        attributes = { ID: instance_id,
                       Name: metadata_instance.name,
                       validUntil: expires_at.xmlschema }

        root.EntitiesDescriptor(ns, attributes) do |_|
          signature_element
          entities_descriptor_extensions

          render_known_entities(known_entity_list(known_entities))
        end
      end
    end

    def render_known_entities(known_entity_list)
      known_entity_list.each do |e|
        entity_descriptor(e) if e.instance_of? EntityDescriptor
        raw_entity_descriptor(e) if e.instance_of? RawEntityDescriptor
      end
    end

    def known_entity_list(known_entities)
      filter_known_entities(known_entities).map do |ke_list|
        ke_list.find(&:functioning_entity)
               .try(:functioning_entity)
      end
    end

    def entities_descriptor_extensions
      mi = metadata_instance

      root.Extensions do |_|
        publication_info
        registration_info(mi) if mi.registration_info.present?
        key_authority(mi) if mi.ca_key_infos.present?
        entity_attribute(mi.entity_attribute) if mi.entity_attribute.present?
      end
    end

    # Lowest rank for EntitySource where multiple instances of
    # EntityDescriptor represented by the same EntityId exist is authoritative.
    def filter_known_entities(known_entities)
      group_by_eid(known_entities).map do |_, entities|
        sort_eid_hash_by_source_rank(entities)
      end
    end

    def group_by_eid(known_entities)
      known_entities.group_by(&:entity_id)
    end

    def sort_eid_hash_by_source_rank(entities)
      entities.sort_by { |ke| ke.entity_source.try(:rank) }
    end

    def root_entity_descriptor(ke)
      Sequel::Model.db.transaction(isolation: :repeatable) do
        attributes = { ID: instance_id, validUntil: expires_at.xmlschema }
        if ke.entity_descriptor.try(:functioning?)
          entity_descriptor(ke.entity_descriptor, attributes, true)
        elsif ke.raw_entity_descriptor.try(:functioning?)
          raw_entity_descriptor(ke.raw_entity_descriptor, attributes, true)
        end
      end
    end

    C14N_METHOD = 'http://www.w3.org/2001/10/xml-exc-c14n#'
    TRANSFORM_METHODS = %w[
      http://www.w3.org/2000/09/xmldsig#enveloped-signature
      http://www.w3.org/2001/10/xml-exc-c14n#
    ].freeze

    SIGNATURE_METHOD = {
      sha1: 'http://www.w3.org/2000/09/xmldsig#rsa-sha1',
      sha256: 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256'
    }.with_indifferent_access

    DIGEST_METHOD = {
      sha1: 'http://www.w3.org/2000/09/xmldsig#sha1',
      sha256: 'http://www.w3.org/2001/04/xmlenc#sha256'
    }.with_indifferent_access

    private_constant :C14N_METHOD, :TRANSFORM_METHODS, :SIGNATURE_METHOD,
                     :DIGEST_METHOD

    def signature_element
      hash_algorithm = metadata_instance.hash_algorithm

      ds.Signature(ns) do |_|
        ds.SignedInfo do
          ds.CanonicalizationMethod(Algorithm: C14N_METHOD)
          ds.SignatureMethod(Algorithm: SIGNATURE_METHOD[hash_algorithm])

          ds.Reference(URI: "##{instance_id}") do
            ds.Transforms do
              TRANSFORM_METHODS.each do |method|
                ds.Transform(Algorithm: method)
              end
            end

            ds.DigestMethod(Algorithm: DIGEST_METHOD[hash_algorithm])
            ds.DigestValue('')
          end
        end

        ds.SignatureValue('')

        ds.KeyInfo do
          ds.KeyValue do
            ds.RSAKeyValue do
              ds.Modulus(openssl_bn_to_base64(certificate.public_key.n))
              ds.Exponent(openssl_bn_to_base64(certificate.public_key.e))
            end
          end

          ds.X509Data do
            b64 = Base64.strict_encode64(certificate.to_der)
            ds.X509Certificate(b64.scan(/.{1,64}/).join("\n"))
          end
        end
      end
    end

    def key_authority(ed)
      shibmd.KeyAuthority(VerifyDepth: ed.ca_verify_depth) do |_|
        ed.ca_key_infos { |ds| ds.order(:data) }.each do |ca|
          key_info(ca)
        end
      end
    end

    def key_info(ki)
      ds.KeyInfo(ns) do |_|
        ds.X509Data do |_|
          ds.X509SubjectName ki.subject if ki.subject.present?
          ds.X509Certificate ki.certificate_without_anchors
        end
      end
    end

    def publication_info(ed = nil)
      publication_info = ed.try(:publication_info) ||
                         metadata_instance.publication_info

      attrs = { publisher: publication_info.publisher,
                creationInstant: created_at.xmlschema,
                publicationId: instance_id }

      mdrpi.PublicationInfo(ns, attrs) do |_|
        publication_info.usage_policies { |ds| ds.order(:id) }.each do |up|
          mdrpi.UsagePolicy(up.uri, 'xml:lang' => up.lang)
        end
      end
    end

    def entity_attribute(ea)
      mdattr.EntityAttributes(ns) do |_|
        ea.attributes { |ds| ds.order(:name) }.each do |attr|
          attribute(attr)
        end
      end
    end

    def attribute(attr)
      saml.Attribute(ns) do |a|
        attribute_base(attr, a)
      end
    end

    def attribute_value(attr_val)
      saml.AttributeValue(ns, attr_val.value)
    end

    def raw_entity_descriptor(red, attributes = {}, root_node = false)
      return root << red.xml unless root_node

      # A dodgy hack to prevent Nokogiri from adding 'default' as a
      # namespace to xmlns elements moved from this document to our actual
      # EntityDescriptor builder, <default:IDPSSODescriptor> wtf Nokogiri...
      xmlns_stripped_input = red.xml.gsub(/xmlns=".+?"/, '')
      parsed_xml = Nokogiri::XML(xmlns_stripped_input, 'UTF-8')

      root.EntityDescriptor(ns, attributes, entityID: red.entity_id.uri) do |_|
        signature_element
      end

      parsed_xml.root.elements.each do |element|
        builder.doc.root << element.clone
      end
    end

    def entity_descriptor(ed, attributes = {}, root_node = false)
      root.EntityDescriptor(ns, attributes, entityID: ed.entity_id.uri) do |_|
        signature_element if root_node
        entity_descriptor_extensions(ed, root_node)

        ed.idp_sso_descriptors { |ds| ds.order(:id) }.each do |idp|
          idp_sso_descriptor(idp) if idp.functioning?
        end

        ed.sp_sso_descriptors { |ds| ds.order(:id) }.each do |sp|
          sp_sso_descriptor(sp) if sp.functioning?
        end

        ed.attribute_authority_descriptors { |ds| ds.order(:id) }.each do |aad|
          attribute_authority_descriptor(aad) if aad.functioning?
        end

        organization(ed.organization)

        contact_people = ed.contact_people do |ds|
          ds.order(:contact_type_id, :contact_id)
        end

        contact_people.each do |cp|
          contact_person(cp)
        end

        sirtfi_contact_people = ed.sirtfi_contact_people do |ds|
          ds.order(:contact_id)
        end

        sirtfi_contact_people.each do |cp|
          sirtfi_contact_person(cp)
        end
      end
    end

    def entity_descriptor_extensions(ed, root_node)
      root.Extensions do |_|
        publication_info(ed) if root_node
        registration_info(ed)
        entity_attribute(ed.entity_attribute) if ed.entity_attribute?
        root << ed.extensions if ed.extensions.present?
      end
    end

    def registration_info(mi)
      attributes = {
        registrationAuthority: mi.registration_info.registration_authority,
        registrationInstant: mi.registration_info
                               .registration_instant_utc.xmlschema
      }
      mdrpi.RegistrationInfo(ns, attributes) do |_|
        rps = mi.registration_info
                .registration_policies { |ds| ds.order(:uri, :lang) }
        rps.each do |rp|
          mdrpi.RegistrationPolicy(rp.uri, 'xml:lang' => rp.lang)
        end
      end
    end

    def organization(org)
      root.Organization(ns) do |_|
        org.organization_names { |ds| ds.order(:value, :lang) }.each do |name|
          root.OrganizationName(name.value, 'xml:lang' => name.lang)
        end

        org.organization_display_names { |ds| ds.order(:value, :lang) }
           .each do |dname|
          root.OrganizationDisplayName(dname.value, 'xml:lang' => dname.lang)
        end

        org.organization_urls { |ds| ds.order(:uri, :lang) }.each do |url|
          root.OrganizationURL(url.uri, 'xml:lang' => url.lang)
        end
      end
    end

    def contact_person(cp)
      attributes = { contactType: cp.contact_type }
      c = cp.contact
      root.ContactPerson(ns, attributes) do |_|
        root.Company(c.company) if c.company.present?
        root.GivenName(c.given_name) if c.given_name.present?
        root.SurName(c.surname) if c.surname.present?
        root.EmailAddress("mailto:#{c.email_address}") if c.email_address.present?
        root.TelephoneNumber(c.telephone_number) if c.telephone_number.present?
      end
    end

    def sirtfi_contact_person(cp)
      attributes = {
        contactType: 'other',
        'remd:contactType': 'http://refeds.org/metadata/contactType/security'
      }

      c = cp.contact
      root.ContactPerson(ns, attributes) do |_|
        root.Company(c.company) if c.company.present?
        root.GivenName(c.given_name) if c.given_name.present?
        root.SurName(c.surname) if c.surname.present?
        root.EmailAddress("mailto:#{c.email_address}") if c.email_address.present?
        root.TelephoneNumber(c.telephone_number) if c.telephone_number.present?
      end
    end

    def role_descriptor(rd, scope)
      scope.parent[:protocolSupportEnumeration] =
        rd.protocol_supports.map(&:uri).sort.join(' ')
      scope.parent[:errorURL] = rd.error_url if rd.error_url.present?

      role_descriptor_extensions(rd, scope)

      rd.key_descriptors { |ds| ds.order(:id) }.each do |kd|
        key_descriptor(kd) unless kd.disabled
      end

      rd.contact_people { |ds| ds.order(:id) }.each { |cp| contact_person(cp) }
    end

    def role_descriptor_extensions(rd, scope)
      return unless rd.extensions?

      scope.Extensions do |_|
        ui_info(rd.ui_info) if rd.ui_info.present?

        if rd.scopes?
          rd.scopes { |ds| ds.order(:value, :regexp) }.each do |s|
            shibmd_scope(s)
          end
        end

        # IDPSSODescriptor specific
        if rd.is_a? IDPSSODescriptor
          disco_hints(rd.disco_hints) if rd.disco_hints.present?
        end

        # SPSSODescriptor specific
        if rd.is_a? SPSSODescriptor
          rd.discovery_response_services { |ds| ds.order(:index, :location) }
            .each do |rds|
            idpdisc.DiscoveryResponse do |rds_node|
              indexed_endpoint(rds, rds_node)
            end
          end
        end

        # General extensions text data supplied by RoleDescriptor
        scope << rd.extensions if rd.extensions.present?
      end
    end

    def key_descriptor(kd)
      attributes = {}
      attributes[:use] = kd.key_type if kd.key_type?
      root.KeyDescriptor(ns, attributes) do |_|
        key_info(kd.key_info)
      end
    end

    def sso_descriptor(sso, scope)
      role_descriptor(sso, scope)

      sso.artifact_resolution_services { |ds| ds.order(:index, :location) }
         .each { |ars| artifact_resolution_service(ars) }

      slos = sso.single_logout_services do |ds|
        ds.order(:location, :binding, :response_location)
      end
      slos.each do |slo|
        single_logout_service(slo)
      end

      nmids = sso.manage_name_id_services do |ds|
        ds.order(:location, :binding, :response_location)
      end
      nmids.each do |slo|
        manage_name_id_service(slo)
      end

      sso.name_id_formats { |ds| ds.order(:uri) }.each do |ndif|
        root.NameIDFormat(ndif.uri)
      end
    end

    def endpoint(ep, scope)
      scope.parent[:Binding] = ep.binding
      scope.parent[:Location] = ep.location

      return unless ep.response_location?

      scope.parent[:ResponseLocation] = ep.response_location
    end

    def indexed_endpoint(ep, scope)
      scope.parent[:index] = ep.index
      scope.parent[:isDefault] = ep.is_default
      endpoint(ep, scope)
    end

    def artifact_resolution_service(endpoint)
      root.ArtifactResolutionService do |ars_node|
        indexed_endpoint(endpoint, ars_node)
      end
    end

    def single_logout_service(ep)
      root.SingleLogoutService do |slo_node|
        endpoint(ep, slo_node)
      end
    end

    def manage_name_id_service(ep)
      root.ManageNameIDService do |mnid_node|
        endpoint(ep, mnid_node)
      end
    end

    def idp_sso_descriptor(idp)
      root.IDPSSODescriptor(ns) do |idp_node|
        sso_descriptor(idp, idp_node)

        ssoss = idp.single_sign_on_services do |ds|
          ds.order(:location, :binding, :response_location)
        end
        ssoss.each { |ssos| single_sign_on_service(ssos) }

        nidmss = idp.name_id_mapping_services do |ds|
          ds.order(:location, :binding, :response_location)
        end
        nidmss.each { |nidms| name_id_mapping_service(nidms) }

        aidrss = idp.assertion_id_request_services do |ds|
          ds.order(:location, :binding, :response_location)
        end
        aidrss.each { |aidrs| assertion_id_request_service(aidrs) }

        idp.attribute_profiles { |ds| ds.order(:uri) }
           .each { |ap| root.AttributeProfile(ap.uri) }

        idp.attributes { |ds| ds.order(:name) }.each { |a| attribute(a) }
      end
    end

    def single_sign_on_service(ep)
      root.SingleSignOnService do |ssos_node|
        endpoint(ep, ssos_node)
      end
    end

    def name_id_mapping_service(ep)
      root.NameIDMappingService do |nidms_node|
        endpoint(ep, nidms_node)
      end
    end

    def assertion_id_request_service(ep)
      root.AssertionIDRequestService do |aidrs_node|
        endpoint(ep, aidrs_node)
      end
    end

    def sp_sso_descriptor(sp)
      root.SPSSODescriptor(ns) do |sp_node|
        sso_descriptor(sp, sp_node)

        sp.assertion_consumer_services { |ds| ds.order(:index, :location) }
          .each { |acs| assertion_consumer_service(acs) }

        acs = sp.attribute_consuming_services do |ds|
          ds.qualify
            .association_join(:service_names)
            .order(Sequel.qualify(:service_names, :value))
            .distinct
        end
        acs.each { |attrcs| attribute_consuming_service(attrcs) }
      end
    end

    def assertion_consumer_service(ep)
      root.AssertionConsumerService do |acs_node|
        indexed_endpoint(ep, acs_node)
      end
    end

    def attribute_consuming_service(acs)
      attributes = {
        index: acs.index,
        isDefault: acs.default
      }
      root.AttributeConsumingService(ns, attributes) do |_acs_node|
        acs.service_names { |ds| ds.order(:value, :lang) }
           .each do |service_name|
          root.ServiceName(service_name.value, 'xml:lang' => service_name.lang)
        end

        acs.service_descriptions { |ds| ds.order(:value, :lang) }
           .each do |desc|
          root.ServiceDescription(desc.value, 'xml:lang' => desc.lang)
        end

        acs.requested_attributes { |ds| ds.order(:name) }.each do |ra|
          requested_attribute(ra)
        end
      end
    end

    def requested_attribute(attr)
      attributes = { isRequired: attr.required }
      root.RequestedAttribute(ns, attributes) do |ra|
        attribute_base(attr, ra)
      end
    end

    def attribute_authority_descriptor(aad)
      root.AttributeAuthorityDescriptor(ns) do |aad_node|
        role_descriptor(aad, aad_node)

        attribute_services = aad.attribute_services do |ds|
          ds.order(:location, :binding, :response_location)
        end
        attribute_services.each do |as|
          attribute_service(as)
        end

        aidrss = aad.assertion_id_request_services do |ds|
          ds.order(:location, :binding, :response_location)
        end
        aidrss.each { |aidrs| assertion_id_request_service(aidrs) }

        aad.name_id_formats { |ds| ds.order(:uri) }.each do |nidf|
          root.NameIDFormat(nidf.uri)
        end

        aad.attribute_profiles { |ds| ds.order(:uri) }.each do |ap|
          root.AttributeProfile(ap.uri)
        end

        aad.attributes { |ds| ds.order(:name) }.each do |attr|
          attribute(attr)
        end
      end
    end

    def attribute_service(ep)
      root.AttributeService do |as_node|
        endpoint(ep, as_node)
      end
    end

    def shibmd_scope(scope)
      shibmd.Scope(ns, scope.value, regexp: scope.regexp)
    end

    def ui_info(info)
      mdui.UIInfo(ns) do |_|
        info.display_names { |ds| ds.order(:value, :lang) }
            .each do |display_name|
          mdui.DisplayName(display_name.value, 'xml:lang' => display_name.lang)
        end

        info.descriptions { |ds| ds.order(:value, :lang) }.each do |description|
          mdui.Description(description.value, 'xml:lang' => description.lang)
        end

        info.keyword_lists { |ds| ds.order(:content, :lang) }.each do |keywords|
          mdui.Keywords(keywords.content, 'xml:lang' => keywords.lang)
        end

        info.logos { |ds| ds.order(:uri, :lang) }.each do |logo|
          attributes = { height: logo.height, width: logo.width }
          attributes['xml:lang'] = logo.lang if logo.lang.present?
          mdui.Logo(logo.uri, attributes)
        end

        info.information_urls { |ds| ds.order(:uri, :lang) }.each do |url|
          mdui.InformationURL(url.uri, 'xml:lang' => url.lang)
        end

        info.privacy_statement_urls { |ds| ds.order(:uri, :lang) }.each do |url|
          mdui.PrivacyStatementURL(url.uri, 'xml:lang' => url.lang)
        end
      end
    end

    def disco_hints(disco)
      mdui.DiscoHints(ns) do |_|
        disco.ip_hints { |ds| ds.order(:block) }.each do |ip_hint|
          mdui.IPHint(ip_hint.block)
        end

        disco.domain_hints { |ds| ds.order(:domain) }.each do |domain_hint|
          mdui.DomainHint(domain_hint.domain)
        end

        disco.geolocation_hints { |ds| ds.order(:uri) }.each do |gh|
          mdui.GeolocationHint(gh.uri)
        end
      end
    end

    def openssl_bn_to_base64(bn)
      Base64.strict_encode64([bn.to_s(16)].pack('H*'))
    end
  end
end

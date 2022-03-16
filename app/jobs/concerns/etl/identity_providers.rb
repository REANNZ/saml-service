# frozen_string_literal: true

module Etl
  module IdentityProviders
    include SSODescriptors

    def identity_providers(ed, ed_data)
      ed_data[:saml][:identity_providers].each do |idp_ref|
        idp_data = fr_identity_providers[idp_ref[:id]]
        next unless process_idp?(idp_data)

        create_or_update_idp(ed, IDPSSODescriptor.dataset, idp_data)
      end
    end

    def process_idp?(idp_data)
      !idp_data[:saml].key?(:single_sign_on_services) ||
        idp_data[:saml][:single_sign_on_services].count < 1 ||
        !idp_data[:attribute_authority_only]
    end

    def create_or_update_idp(ed, ds, idp_data)
      attrs = idp_attrs(idp_data)
      idp = create_or_update_by_fr_id(ds, idp_data[:id], attrs) do |obj|
        obj.entity_descriptor = ed
        obj.organization = ed.organization
        ed.known_entity.tag_as(Tag::IDP)
      end

      idp_saml_core(idp, idp_data)
      mdui(idp, idp_data[:display_name], idp_data[:description])
    end

    def idp_attrs(idp_data)
      saml = idp_data[:saml]
      {
        created_at: Time.zone.parse(idp_data[:created_at]),
        enabled: idp_data[:functioning],
        error_url: saml[:sso_descriptor][:role_descriptor][:error_url],
        want_authn_requests_signed: saml[:authnrequests_signed]
      }
    end

    def idp_saml_core(idp, idp_data)
      saml = idp_data[:saml]
      sso_descriptor(idp, saml[:sso_descriptor], saml[:scope])

      single_sign_on_services(idp, saml[:single_sign_on_services])
      name_id_mapping_services(idp, saml[:name_id_mapping_services])
      assertion_id_request_services(idp, saml[:assertion_id_request_services])

      attributes(idp, saml[:attributes])
      attribute_profiles(idp, saml[:attribute_profiles])
    end

    def single_sign_on_services(idp, ssoservices_data)
      idp.single_sign_on_services.each(&:destroy)
      ssoservices_data.each do |sso_data|
        next unless sso_data[:functioning]

        sso = SingleSignOnService.new(location: sso_data[:location],
                                      binding: sso_data[:binding][:uri])
        idp.add_single_sign_on_service(sso)
      end
    end

    def name_id_mapping_services(idp, nidms_services_data)
      idp.name_id_mapping_services.each(&:destroy)
      nidms_services_data.each do |nidms_data|
        next unless nidms_data[:functioning]

        nidms = NameIdMappingService.new(location: nidms_data[:location],
                                         binding: nidms_data[:binding][:uri])
        idp.add_name_id_mapping_service(nidms)
      end
    end

    def assertion_id_request_services(idp, aidrs_services_data)
      idp.assertion_id_request_services.each(&:destroy)
      aidrs_services_data.each do |aidrs_data|
        next unless aidrs_data[:functioning]

        aidrs =
          AssertionIdRequestService.new(location: aidrs_data[:location],
                                        binding: aidrs_data[:binding][:uri])
        idp.add_assertion_id_request_service(aidrs)
      end
    end

    def attribute_profiles(idp, aps_data)
      idp.attribute_profiles.each(&:destroy)
      aps_data.each do |ap_data|
        ap = AttributeProfile.new(uri: ap_data[:uri])
        idp.add_attribute_profile(ap)
      end
    end

    def attributes(idp, attrs_data)
      destroy_attributes(idp)
      attrs_data.each do |attr_data|
        base = fr_attributes[attr_data[:id]]

        attr = Attribute.create(name: "urn:oid:#{base[:oid]}",
                                friendly_name: attr_data[:name],
                                description: base[:description],
                                oid: base[:oid])
        idp.add_attribute(attr)
        NameFormat.create(uri: base[:name_format][:uri], attribute: attr)
      end
    end

    def destroy_attributes(idp)
      idp.attributes.each do |attr|
        attr.name_format&.destroy
        attr.destroy
      end
    end
  end
end

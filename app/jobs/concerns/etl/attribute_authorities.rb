# frozen_string_literal: true

module Etl
  module AttributeAuthorities
    include RoleDescriptors

    def attribute_authorities(ed, ed_data)
      ed_data[:saml][:attribute_authorities].each do |aa_ref|
        aa_data = fr_attribute_authorities[aa_ref[:id]]

        create_or_update_aa(ed, AttributeAuthorityDescriptor.dataset, aa_data)
      end
    end

    def create_or_update_aa(ed, ds, aa_data)
      attrs = aa_attrs(aa_data)
      aa = create_or_update_by_fr_id(ds, aa_data[:id], attrs) do |obj|
        obj.entity_descriptor = ed
        obj.organization = ed.organization
        add_aa_tag(ed)
      end
      aa_saml_core(aa, aa_data)
    end

    def aa_attrs(aa_data)
      {
        created_at: Time.zone.parse(aa_data[:created_at]),
        enabled: aa_data[:functioning]
      }
    end

    def add_aa_tag(ed)
      if ed.idp_sso_descriptors.present?
        ed.known_entity.tag_as(Tag::AA)
      else
        ed.known_entity.tag_as(Tag::STANDALONE_AA)
      end
    end

    def aa_saml_core(aa, aa_data)
      saml, rd_data, nidf_data = extract_aa_data(aa_data)

      role_descriptor(aa, rd_data, saml[:scope])
      assertion_id_request_services(aa, saml[:assertion_id_request_services])
      name_id_formats(aa, nidf_data)
      attributes(aa, saml[:attributes])
      attribute_profiles(aa, saml[:attribute_profiles])
      attribute_services(aa, aa_data[:saml][:attribute_services])
    end

    def extract_aa_data(aa_data)
      return extract_aa_data_idp(aa_data) if standalone_aa?(aa_data)

      raise 'Does not support AA (even standalone) who do not derive from IdP'
    end

    def extract_aa_data_idp(aa_data)
      idp_data = fr_identity_providers[aa_data[:saml][:idp_sso_descriptor]]
      saml = idp_data[:saml]
      rd_data = saml[:sso_descriptor][:role_descriptor]
      nidf_data = saml[:sso_descriptor][:name_id_formats]

      [saml, rd_data, nidf_data]
    end

    def attribute_services(aa, attr_services_data)
      aa.attribute_services.each(&:destroy)
      attr_services_data.each do |attrs_data|
        next unless attrs_data[:functioning]

        attrs =
          AttributeService.new(location: attrs_data[:location],
                               binding: attrs_data[:binding][:uri])
        aa.add_attribute_service(attrs)
      end
    end

    def standalone_aa?(aa_data)
      aa_data[:saml][:extract_metadata_from_idp_sso_descriptor]
    end
  end
end

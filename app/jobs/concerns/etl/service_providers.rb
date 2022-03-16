# frozen_string_literal: true

module Etl
  module ServiceProviders
    include SSODescriptors

    def service_providers(ed, ed_data)
      ed_data[:saml][:service_providers].each do |sp_ref|
        data = fr_service_providers[sp_ref[:id]]
        acs = data[:saml].try!(:[], :attribute_consuming_services)
        next unless acs.try!(&:any?)

        create_or_update_sp(ed, SPSSODescriptor.dataset, data)
      end
    end

    def create_or_update_sp(ed, ds, sp_data)
      attrs = sp_attrs(sp_data)
      sp = create_or_update_by_fr_id(ds, sp_data[:id], attrs) do |obj|
        obj.entity_descriptor = ed
        obj.organization = ed.organization
        ed.known_entity.tag_as(Tag::SP)
      end

      sp_saml_core(sp, sp_data)
      mdui(sp, sp_data[:display_name], sp_data[:description])
    end

    def sp_attrs(sp_data)
      saml = sp_data[:saml]
      {
        created_at: Time.zone.parse(sp_data[:created_at]),
        enabled: sp_data[:functioning],
        authn_requests_signed: saml[:authnrequests_signed],
        want_assertions_signed: saml[:assertions_signed]
      }
    end

    def sp_saml_core(sp, sp_data)
      saml = sp_data[:saml]
      sso_descriptor(sp, saml[:sso_descriptor])

      assertion_consumer_services(sp, saml[:assertion_consumer_services])
      discovery_response_services(sp, saml[:discovery_response_services])
      attribute_consuming_services(sp, saml[:attribute_consuming_services])
    end

    def assertion_consumer_services(sp, acservices_data)
      sp.assertion_consumer_services.each(&:destroy)
      acservices_data.each do |acs_data|
        next unless acs_data[:functioning]

        acs = AssertionConsumerService.new(is_default: acs_data[:is_default],
                                           index: acs_data[:index],
                                           location: acs_data[:location],
                                           binding: acs_data[:binding][:uri])
        sp.add_assertion_consumer_service(acs)
      end
    end

    def discovery_response_services(sp, drservices_data)
      sp.discovery_response_services.each(&:destroy)
      drservices_data.each do |drs_data|
        next unless drs_data[:functioning]

        drs = DiscoveryResponseService.new(is_default: drs_data[:is_default],
                                           index: drs_data[:index],
                                           location: drs_data[:location],
                                           binding: drs_data[:binding][:uri])
        sp.add_discovery_response_service(drs)
      end
    end

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def attribute_consuming_services(sp, acservices_data)
      sp.attribute_consuming_services.each(&:destroy)
      acservices_data.each_with_index do |ac_data, i|
        requested_attributes = ac_data[:attributes].select do |ra|
          ra[:approved] && correctly_specified?(ra)
        end
        next if requested_attributes.empty?

        service_name = ServiceName.new(value: ac_data[:names][0], lang: 'en')
        acs = AttributeConsumingService.create(index: i + 1, default: ac_data[:is_default],
                                               sp_sso_descriptor: sp)
        acs.add_service_name(service_name)
        acs_attributes(acs, requested_attributes)
      end
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

    def acs_attributes(acs, requested_attributes)
      requested_attributes.each do |attr_data|
        base = fr_attributes[attr_data[:id]]
        ra = requested_attribute(acs, attr_data, base)
        acs.add_requested_attribute(ra)
        NameFormat.create(uri: base[:name_format][:uri], attribute: ra)
      end
    end

    def correctly_specified?(attr_data)
      # Don't represent attributes that require specification but
      # have not yet had specific values associated.
      # For example eduPersonEntitlement but no entitlement values
      # requested by the SP using our tooling as yet.
      attr_data.fetch(:specification, false) == false ||
        (attr_data[:specification] && attr_data[:values].present?)
    end

    def requested_attribute(acs, attr_data, base)
      ra = RequestedAttribute.create(name: "urn:oid:#{base[:oid]}",
                                     friendly_name: attr_data[:name],
                                     description: base[:description],
                                     oid: base[:oid],
                                     required: attr_data[:is_required],
                                     reasoning: attr_data[:reason],
                                     attribute_consuming_service: acs)

      add_values_to_requested_attribute(ra, attr_data)
      ra
    end

    def add_values_to_requested_attribute(ra, attr_data)
      attr_data[:values].each do |av|
        next unless av[:approved]

        ra.add_attribute_value(value: av[:value])
      end
    end
  end
end

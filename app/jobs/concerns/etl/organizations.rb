# frozen_string_literal: true

module Etl
  module Organizations
    def organizations
      fr_organizations.each do |org_data|
        organization(org_data)
      end
    end

    def organization(org_data)
      ds = Organization.dataset
      o = create_or_update_by_fr_id(ds, org_data[:id], org_attrs(org_data))
      organization_name(o, org_data)
      organization_display_name(o, org_data)
      organization_url(o, org_data)

      entity_descriptors(o, org_data)
    end

    def org_attrs(org_data)
      return {} unless org_data[:created_at]

      { created_at: Time.zone.parse(org_data[:created_at]) }
    end

    def organization_name(o, org_data)
      o.organization_names.each(&:destroy)
      OrganizationName.create(organization: o,
                              value: org_data[:domain],
                              lang: org_data[:lang])
    end

    def organization_display_name(o, org_data)
      o.organization_display_names.each(&:destroy)
      OrganizationDisplayName.create(organization: o,
                                     value: org_data[:display_name],
                                     lang: org_data[:lang])
    end

    def organization_url(o, org_data)
      o.organization_urls.each(&:destroy)
      OrganizationURL.create(organization: o,
                             uri: org_data[:url],
                             lang: org_data[:lang])
    end
  end
end

# frozen_string_literal: true

module Etl
  module SSODescriptors
    include RoleDescriptors

    def sso_descriptor(sd, sd_data, scopes_data = nil)
      rd_data = sd_data[:role_descriptor]
      role_descriptor(sd, rd_data, scopes_data)

      name_id_formats(sd, sd_data[:name_id_formats])
      artifact_resolution_services(sd, sd_data[:artifact_resolution_services])
      single_logout_services(sd, sd_data[:single_logout_services])
      manage_name_id_services(sd, sd_data[:manage_nameid_services])
    end

    def name_id_formats(sd, nidfs_data)
      sd.name_id_formats.each(&:destroy)
      nidfs_data.each do |nidf_data|
        nidf = NameIdFormat.create(uri: nidf_data[:uri])
        sd.add_name_id_format(nidf)
      end
    end

    def artifact_resolution_services(sd, arservices_data)
      sd.artifact_resolution_services.each(&:destroy)
      arservices_data.each do |ars_data|
        next unless ars_data[:functioning]

        ars = ArtifactResolutionService.new(is_default: ars_data[:is_default],
                                            index: ars_data[:index],
                                            location: ars_data[:location],
                                            binding: ars_data[:binding][:uri])
        sd.add_artifact_resolution_service(ars)
      end
    end

    def single_logout_services(sd, slservices_data)
      sd.single_logout_services.each(&:destroy)
      slservices_data.each do |sls_data|
        next unless sls_data[:functioning]

        sls = SingleLogoutService.new(location: sls_data[:location],
                                      binding: sls_data[:binding][:uri])
        sd.add_single_logout_service(sls)
      end
    end

    def manage_name_id_services(sd, mnidservices_data)
      sd.manage_name_id_services.each(&:destroy)
      mnidservices_data.each do |mnids_data|
        next unless mnids_data[:functioning]

        mnids = ManageNameIdService.new(location: mnids_data[:location],
                                        binding: mnids_data[:binding][:uri])
        sd.add_manage_name_id_service(mnids)
      end
    end
  end
end

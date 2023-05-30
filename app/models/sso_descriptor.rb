# frozen_string_literal: true

class SSODescriptor < RoleDescriptor
  one_to_many :artifact_resolution_services
  one_to_many :single_logout_services
  one_to_many :manage_name_id_services
  one_to_many :name_id_formats

  plugin :association_dependencies, artifact_resolution_services: :destroy,
                                    single_logout_services: :destroy,
                                    manage_name_id_services: :destroy,
                                    name_id_formats: :destroy

  def artifact_resolution_services?
    artifact_resolution_services.present?
  end

  def single_logout_services?
    single_logout_services.present?
  end

  def manage_name_id_services?
    manage_name_id_services.present?
  end

  def name_id_formats?
    name_id_formats.present?
  end
end

class SsoDescriptor < RoleDescriptor
  one_to_many :artifact_resolution_services
  one_to_many :single_logout_services
  one_to_many :manage_name_id_services
  one_to_many :name_id_formats, class: :SamlUri

  def validate
    super
  end
end
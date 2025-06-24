# frozen_string_literal: true

class AttributeAuthorityDescriptor < RoleDescriptor
  one_to_many :attribute_services
  one_to_many :assertion_id_request_services
  one_to_many :name_id_formats
  one_to_many :attribute_profiles
  one_to_many :attributes

  plugin :association_dependencies, attribute_services: :destroy,
                                    assertion_id_request_services: :destroy,
                                    name_id_formats: :destroy,
                                    attribute_profiles: :destroy,
                                    attributes: :destroy

  def validate
    super
    validates_presence :attribute_services, allow_missing: new? || !enabled
  end

  def assertion_id_request_services?
    assertion_id_request_services.present?
  end

  def name_id_formats?
    name_id_formats.present?
  end

  def attribute_profiles?
    attribute_profiles.present?
  end

  def attributes?
    attributes.present?
  end
end

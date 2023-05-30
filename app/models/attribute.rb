# frozen_string_literal: true

class Attribute < Sequel::Model
  include Parents

  one_to_one :name_format
  one_to_many :attribute_values

  many_to_one :idp_sso_descriptor
  many_to_one :attribute_authority_descriptor
  many_to_one :entity_attribute, class: 'MDATTR::EntityAttribute'

  plugin :class_table_inheritance, ignore_subclass_columns: %i[created_at updated_at]
  plugin :association_dependencies, name_format: :destroy,
                                    attribute_values: :destroy

  def validate
    super
    validates_presence %i[name created_at updated_at]
    return if new?

    single_parent %i[idp_sso_descriptor attribute_authority_descriptor
                     entity_attribute]
  end
end

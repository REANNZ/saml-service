# frozen_string_literal: true

class SamlURI < Sequel::Model
  # We use SamlURI as the parent class for all
  # URI which the SAML Metadata spec defines as type anyURI.
  # e.g.
  # * ProtocolSupport ( RoleDescriptor > protocolSupportEnumeration )
  # * NameIDFormat ( SSODescriptor > NameIDFormat )
  #
  # n.b. Types, such as LocalizedURI, which extend anyURI are standalone
  # models and not part of the SamlURI hierachy as they are distinct types
  # in their own right.

  plugin :class_table_inheritance, ignore_subclass_columns: [:role_descriptor_id]

  def validate
    super
    validates_presence %i[uri created_at updated_at]
  end
end

class ProtocolSupport < SamlURI
  many_to_one :role_descriptor

  def validate
    super
    validates_presence :role_descriptor, allow_missing: false
  end
end
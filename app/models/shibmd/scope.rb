# frozen_string_literal: true

module Shibmd
  class Scope < Sequel::Model
    many_to_one :role_descriptor, class: 'RoleDescriptor'

    # Locked scopes are not to be removed during ETL processes
    # as they are entered directly to SAML service in order
    # to work around an FR limitation that only supports
    # a single scope per RD.
    def unlocked?
      !locked
    end

    def validate
      super

      validates_presence %i[role_descriptor value regexp
                            created_at updated_at]
    end
  end
end

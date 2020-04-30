# frozen_string_literal: true

module API
  class APISubject < Sequel::Model
    include Accession::Principal

    many_to_many :roles, class: 'Role'

    def permissions
      roles.flat_map { |role| role.permissions.map(&:value) }
    end

    def functioning?
      enabled
    end

    def validate
      validates_presence %i[description
                            contact_name contact_mail enabled
                            created_at updated_at]

      validates_unique :x509_cn
      validates_format(/\A[\w-]+\z/, :x509_cn, allow_blank: true)

      validates_unique :token

      errors.add(:base, 'x509cn AND token cannot both be empty') unless authentication_method?
    end

    private

    def authentication_method?
      x509_cn.present? || token.present?
    end
  end
end

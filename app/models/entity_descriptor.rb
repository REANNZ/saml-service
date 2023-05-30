# frozen_string_literal: true

class EntityDescriptor < Sequel::Model
  many_to_one :known_entity
  many_to_one :organization

  one_to_many :additional_metadata_locations
  one_to_many :contact_people
  one_to_many :sirtfi_contact_people
  one_to_many :role_descriptors
  one_to_many :idp_sso_descriptors
  one_to_many :sp_sso_descriptors
  one_to_many :attribute_authority_descriptors

  one_to_one :entity_id

  one_to_one :registration_info, class: 'MDRPI::RegistrationInfo'
  one_to_one :publication_info, class: 'MDRPI::PublicationInfo'
  one_to_one :entity_attribute, class: 'MDATTR::EntityAttribute'

  plugin :touch
  plugin :association_dependencies, additional_metadata_locations: :destroy,
                                    contact_people: :destroy,
                                    sirtfi_contact_people: :destroy,
                                    role_descriptors: :destroy,
                                    idp_sso_descriptors: :destroy,
                                    sp_sso_descriptors: :destroy,
                                    attribute_authority_descriptors: :destroy,
                                    entity_id: :destroy,
                                    registration_info: :destroy,
                                    publication_info: :destroy,
                                    entity_attribute: :destroy

  def validate
    super
    validates_presence %i[known_entity created_at updated_at]
    validates_presence :entity_id, allow_missing: new?
    validates_presence :role_descriptors, allow_missing: new?
    validates_presence :organization, allow_missing: new?
    validates_presence :registration_info, allow_missing: new?
  end

  def functioning?
    valid? && enabled && functional_role_descriptor?
  end

  def edugain_compliant?
    functioning? &&
      edugain_compliant_contacts? &&
      edugain_compliant_idp? &&
      edugain_compliant_sp?
  end

  def edugain_compliant_contacts?
    technical_contact_count.positive? || support_contact_count.positive?
  end

  def edugain_compliant_idp?
    idp_sso_descriptors.each do |idp|
      return false unless idp.functioning? && idp.edugain_compliant?
    end

    true
  end

  def edugain_compliant_sp?
    sp_sso_descriptors.each do |sp|
      return false unless sp.functioning? && sp.edugain_compliant?
    end

    true
  end

  def entity_attribute?
    entity_attribute.present?
  end

  protected

  def technical_contact_count
    ContactPerson.join(:entity_descriptors, id: :entity_descriptor_id)
                 .where(Sequel.qualify(:entity_descriptors, :id) => id)
                 .where(Sequel.qualify(:contact_people, :contact_type_id) =>
           ContactPerson::TYPE[:technical])
                 .count
  end

  def support_contact_count
    ContactPerson.join(:entity_descriptors, id: :entity_descriptor_id)
                 .where(Sequel.qualify(:entity_descriptors, :id) => id)
                 .where(Sequel.qualify(:contact_people, :contact_type_id) =>
           ContactPerson::TYPE[:support])
                 .count
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def functional_role_descriptor?
    sp_sso_descriptors.any?(&:functioning?) ||
      idp_sso_descriptors.any?(&:functioning?) ||
      attribute_authority_descriptors.any?(&:functioning?) ||
      role_descriptors.any?(&:functioning?)
  end
  # rubocop:enable Metrics/CyclomaticComplexity
end

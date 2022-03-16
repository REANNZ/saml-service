# frozen_string_literal: true

class UpdateFromFederationRegistry
  include QueryFederationRegistry
  include StoreFederationRegistryData

  attr_reader :fr_source, :source

  include Etl::Contacts
  include Etl::Organizations
  include Etl::EntityDescriptors
  include Etl::IdentityProviders
  include Etl::AttributeAuthorities
  include Etl::ServiceProviders

  def self.perform(id:)
    new(id: id).perform
  end

  def initialize(id:)
    @cache = {}
    @fr_source = FederationRegistrySource[id]
    @source = @fr_source.entity_source
  end

  def perform
    Sequel::Model.db.transaction do
      contacts
      organizations
    end
    true
  end
end

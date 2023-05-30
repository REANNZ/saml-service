# frozen_string_literal: true

module API
  class DiscoveryEntities
    def generate_cached_json(reset_cache: false, cache_expiry: 60.minutes)
      Sequel::Model.db.transaction(isolation: :repeatable) do
        Rails.cache.fetch('discovery_entities', expires_in: cache_expiry, force: reset_cache) do
          generate_json
        end
      end
    end

    private

    def generate_json
      DiscoveryEntitiesController.render(template: 'api/discovery_entities/index', assigns: {
                                           identity_provider_entities:,
                                           service_provider_entities:
                                         })
    end

    def identity_provider_entities
      filter_by_rank(ed_containing_idp + red_containing_idp)
    end

    def service_provider_entities
      filter_by_rank(ed_containing_sp + red_containing_sp)
    end

    COMMON_EAGER_FETCH = {
      entity_id: [],
      known_entity: :tags,
      role_descriptors: [],
      organization: [],
      registration_info: []
    }.freeze

    SP_EAGER_FETCH = COMMON_EAGER_FETCH.merge(
      sp_sso_descriptors: {
        ui_info: %i[logos descriptions display_names information_urls
                    privacy_statement_urls],
        discovery_response_services: []
      }
    )

    IDP_EAGER_FETCH = COMMON_EAGER_FETCH.merge(
      idp_sso_descriptors: {
        ui_info: %i[logos descriptions display_names],
        disco_hints: %i[geolocation_hints domain_hints]
      }
    )

    RAW_COMMON_EAGER_FETCH = {
      entity_id: [],
      known_entity: :tags
    }.freeze

    RAW_IDP_EAGER_FETCH = RAW_COMMON_EAGER_FETCH

    RAW_SP_EAGER_FETCH = RAW_COMMON_EAGER_FETCH

    private_constant :COMMON_EAGER_FETCH, :SP_EAGER_FETCH, :IDP_EAGER_FETCH,
                     :RAW_COMMON_EAGER_FETCH, :RAW_IDP_EAGER_FETCH,
                     :RAW_SP_EAGER_FETCH

    def filter_by_rank(entities)
      entities.collect(&:known_entity)
              .group_by(&:entity_id)
              .map { |_, es| functioning_entity(order_by_rank(es)) }
              .compact
    end

    def order_by_rank(known_entities)
      known_entities.sort_by { |ke| ke.entity_source.try(:rank) }
    end

    def functioning_entity(known_entities_by_rank)
      known_entities_by_rank.find(&:functioning_entity)
                            .try(:functioning_entity)
    end

    def ed_containing_sp
      entities_with_role_descriptor(:sp_sso_descriptors)
        .eager(SP_EAGER_FETCH).all
    end

    def red_containing_sp
      RawEntityDescriptor.where(sp: true).eager(known_entity: :tags)
                         .eager(RAW_SP_EAGER_FETCH).all
    end

    def ed_containing_idp
      entities_with_role_descriptor(:idp_sso_descriptors)
        .eager(IDP_EAGER_FETCH).all
    end

    def red_containing_idp
      RawEntityDescriptor.where(idp: true).eager(known_entity: :tags)
                         .eager(RAW_IDP_EAGER_FETCH).all
    end

    def entities_with_role_descriptor(table)
      EntityDescriptor.qualify.distinct(:id)
                      .join(table, entity_descriptor_id: :id)
    end
  end
end

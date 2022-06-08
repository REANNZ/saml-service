# frozen_string_literal: true

module Etl
  module EntityDescriptors
    def entity_descriptors(o, org_data)
      org_data[:saml][:entity_descriptors].each do |ed_ref|
        ed_data = fr_entity_descriptors[ed_ref[:id]]

        if !ed_data[:functioning] || ed_data[:saml][:empty]
          destroy_existing_ed(ed_data)
        else
          create_or_update_ed(o, EntityDescriptor.dataset, ed_data)
        end
      end
    end

    def create_or_update_ed(o, ds, ed_data)
      Rails.logger.info "Processing FR entity #{ed_data[:entity_id]}"

      begin
        ed = create_or_update_ed_from_fr(o, ds, ed_data)
        ed_saml_core(ed, ed_data)
        indicate_content_updated(ed.known_entity)
      rescue Sequel::ValidationFailed => e
        Rails.logger.error "Evicted FR entity #{ed_data[:entity_id]}"
        Rails.logger.error e
        raise e
      end
    end

    def create_or_update_ed_from_fr(o, ds, ed_data)
      create_or_update_by_fr_id(ds, ed_data[:id], ed_attrs(ed_data)) do |ed|
        ed.organization = o
        ed.known_entity = known_entity(ed_data)
        ed.known_entity.tag_as(@source.source_tag)
      end
    end

    def known_entity(ed_data)
      KnownEntity.create(entity_source: source, enabled: ed_data[:active])
    end

    def ed_saml_core(ed, ed_data)
      entity_id(ed, ed_data)
      registration_info(ed, ed_data)
      identity_providers(ed, ed_data)
      attribute_authorities(ed, ed_data)
      service_providers(ed, ed_data)
    end

    def ed_attrs(ed_data)
      { created_at: Time.zone.parse(ed_data[:created_at]),
        enabled: ed_data[:functioning] }
    end

    def entity_id(ed, ed_data)
      return ed.entity_id.update(uri: ed_data[:entity_id]) if ed.entity_id

      EntityId.create(uri: ed_data[:entity_id], entity_descriptor: ed)
    end

    def registration_info(ed, ed_data)
      return if ed.registration_info.present?

      ri = MDRPI::RegistrationInfo.create(
        registration_authority: @fr_source.registration_authority,
        registration_instant: Time.zone.parse(ed_data[:created_at]),
        entity_descriptor: ed
      )

      create_registration_info(ri)
    end

    def create_registration_info(ri)
      MDRPI::RegistrationPolicy.create(
        registration_info: ri,
        uri: @fr_source.registration_policy_uri,
        lang: @fr_source.registration_policy_uri_lang
      )
    end

    def indicate_content_updated(ke)
      # Changes updated_at timestamp for associated KnownEntity
      # which is used by MDQP for etag generation / caching.
      ke.touch
    end

    def destroy_existing_ed(ed_data)
      ed =
        FederationRegistryObject.local_instance(ed_data[:id],
                                                EntityDescriptor.dataset)

      return if ed.blank?

      Rails.logger.info "Destroying FR entity #{ed_data[:entity_id]}"
      ke = ed.known_entity
      ed.destroy
      ke.destroy
    end
  end
end

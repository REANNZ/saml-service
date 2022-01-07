# frozen_string_literal: true

module Edugain
  class NonResearchAndScholarshipEntity
    attr_reader :id

    def initialize(id:)
      @id = id
    end

    def approve
      known_entity.tag_as 'aaf-edugain-verified'
      known_entity.touch
    end

    private

    def known_entity
      @known_entity ||= begin
        entity_id = EntityId.first!(uri: id)
        descriptor = entity_id.entity_descriptor || entity_id.raw_entity_descriptor
        descriptor.known_entity
      end
    end
  end
end

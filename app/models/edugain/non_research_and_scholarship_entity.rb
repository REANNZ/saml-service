# frozen_string_literal: true

module Edugain
  class NonResearchAndScholarshipEntity
    attr_reader :id

    def initialize(id:)
      @id = id
    end

    def approve
      descriptor.known_entity.tag_as EdugainHelper::edugain_verified_tag
      descriptor.known_entity.touch
      descriptor.save(raise_on_save_failure: true)
    end

    private

    def descriptor
      @descriptor ||= EntityId[uri: id].tap do |eid|
        raise ArgumentError, 'Could not find an entry for supplied id' if eid.nil?
      end.entity_descriptor
    end
  end
end

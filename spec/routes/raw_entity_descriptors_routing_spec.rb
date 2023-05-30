# frozen_string_literal: true

require 'rails_helper'

RSpec.describe API::RawEntityDescriptorsController, type: :routing do
  let(:entity_source) { create(:entity_source) }
  let(:source_tag) { entity_source.source_tag }
  let(:entity_id) { Faker::Internet.url }
  let(:base64_urlsafe_entity_id) { Base64.urlsafe_encode64(entity_id) }

  it 'routes patch /api/entity_sources/:tag/raw_entity_descriptors' \
     '/:base64_urlsafe_entity_id to #update' do
    expect(patch("/api/entity_sources/#{source_tag}/raw_entity_descriptors/" \
                 "#{base64_urlsafe_entity_id}"))
      .to route_to(
        controller: 'api/raw_entity_descriptors',
        action: 'update',
        tag: source_tag,
        base64_urlsafe_entity_id:,
        format: 'json'
      )
  end
end

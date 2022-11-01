# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Routes for MetadataQueryController', type: :routing do
  let(:instance) { Faker::Lorem.word }
  let(:identifier) { Faker::Internet.url }
  let(:sha1_identifier) { Digest::SHA1.hexdigest identifier }
  let(:basic_identifier) { Faker::Lorem.word }

  it 'routes correctly' do
    expect(get("/mdq/#{instance}/entities"))
      .to route_to(
        controller: 'metadata_query',
        action: 'all_entities',
        instance: instance
      )
    expect(get("/mdq/#{instance}/entities/#{identifier}"))
      .to route_to(
        controller: 'metadata_query',
        action: 'specific_entity',
        instance: instance,
        identifier: identifier
      )
    uri = URI.encode("/mdq/#{instance}/entities/{sha1}#{sha1_identifier}")
    expect(get(uri))
      .to route_to(
        controller: 'metadata_query',
        action: 'specific_entity_sha1',
        instance: instance,
        identifier: "{sha1}#{sha1_identifier}"
      )
    expect(get("/mdq/#{instance}/entities/#{basic_identifier}"))
      .to route_to(
        controller: 'metadata_query',
        action: 'tagged_entities',
        instance: instance,
        identifier: basic_identifier
      )
  end
end

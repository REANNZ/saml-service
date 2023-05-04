# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('bin', 'recache_discovery_entities').to_s

RSpec.describe 'bin/recache_discovery_entities' do
  it 'regenerates the redis cache' do
    Rails.cache.write('discovery_entities', expires_in: 1.hour) do
      'test'
    end
    RecacheDiscoveryEntities.perform
    expect(Rails.cache.read('discovery_entities')).to include('identity_providers')
    expect(Rails.cache.read('discovery_entities')).to include('service_providers')
  end
end

# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('bin', 'sync').to_s

RSpec.describe 'bin/sync' do
  let(:entity_source) { create(:entity_source, :external) }
  let(:fr_source) { create(:federation_registry_source) }

  it 'updates an FR EntitySource reference' do
    expect(UpdateFromFederationRegistry).to receive(:perform)
      .with(id: fr_source.id)
    SyncCLI.perform(fr_source.entity_source.source_tag)
  end

  it 'Updates a standard remote EntitySource reference' do
    expect(UpdateEntitySource).to receive(:perform).with(id: entity_source.id)
    SyncCLI.perform(entity_source.source_tag)
  end

  context 'with invalid id' do
    let(:tag) { 'blah' }

    it 'should raise' do
      expect { SyncCLI.perform(tag) }.to raise_error(StandardError, "The source_tag #{tag} is invalid")
    end
  end
end

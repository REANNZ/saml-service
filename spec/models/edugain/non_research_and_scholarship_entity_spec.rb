# frozen_string_literal: true

require 'rails_helper'

describe Edugain::NonResearchAndScholarshipEntity do
  describe '#approve' do
    subject(:approve) { described_class.new(id: id).approve }

    context 'with an extant entity with an entity descriptor' do
      let(:entity_descriptor) { create(:entity_descriptor, :with_sp) }
      let(:id) { entity_descriptor.entity_id.uri }

      it 'tags the KnownEntity as aaf-edugain-verified' do
        expect(entity_descriptor.known_entity.tags).to be_empty

        approve
        entity_descriptor.reload

        expect(entity_descriptor.known_entity.tags.first.name).to eq 'aaf-edugain-verified'
      end
    end

    context 'with an extant entity with a raw entity descriptor' do
      let(:entity_descriptor) { create(:raw_entity_descriptor_sp) }
      let(:id) { entity_descriptor.entity_id.uri }

      it 'tags the KnownEntity as aaf-edugain-verified' do
        expect(entity_descriptor.known_entity.tags).to be_empty

        approve
        entity_descriptor.reload

        expect(entity_descriptor.known_entity.tags.first.name).to eq 'aaf-edugain-verified'
      end
    end

    context 'with a nonexistent entity' do
      let(:id) { 'foobar' }

      it 'raises Sequel::NoMatchingRow' do
        expect { approve }.to raise_error Sequel::NoMatchingRow
      end
    end
  end
end

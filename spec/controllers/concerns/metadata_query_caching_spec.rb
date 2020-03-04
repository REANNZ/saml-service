# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MetadataQueryCaching do
  let(:klass) { Class.new { include MetadataQueryCaching } }
  subject { klass.new }

  def mocked_entity
    time = Faker::Time.between(from: 1.year.ago, to: 1.week.ago)
    double(KnownEntity, id: rand(1..1000), updated_at: time)
  end

  def mocked_metadata_instance
    FactoryBot.build_stubbed(:metadata_instance)
  end

  describe '.generate_document_entities_etag(instance, entities)' do
    def run(metadata_instance, entities)
      subject.generate_document_entities_etag(metadata_instance, entities)
    end

    let(:metadata_instance) { mocked_metadata_instance }
    let(:initial_entities) { Array.new(5) { mocked_entity } }
    let(:initial_etag) { run(metadata_instance, initial_entities) }
    let(:entities) { initial_entities }
    let(:etag) { run(metadata_instance, entities) }

    it 'is hex-encoded' do
      expect(initial_etag).to match(/\A\h+\z/)
    end

    context 'when a new entity is added' do
      let(:entities) { initial_entities + [mocked_entity] }

      it 'changes' do
        expect(etag).not_to eq(initial_etag)
      end
    end

    context 'when an entity changes its timestamp' do
      let(:replacement) do
        e = initial_entities.first
        double(KnownEntity, id: e.id, updated_at: Time.zone.now)
      end

      let(:entities) { [mocked_entity, *initial_entities.drop(1)] }

      it 'changes' do
        expect(etag).not_to eq(initial_etag)
      end
    end

    context 'when an entity is replaced by another with the same timestamp' do
      let(:replacement) do
        e = initial_entities.first
        double(KnownEntity, id: rand(1000..2000), updated_at: e.updated_at)
      end

      let(:entities) { [replacement, *initial_entities.drop(1)] }

      it 'changes' do
        expect(etag).not_to eq(initial_etag)
      end
    end

    context 'for a different metadata instance' do
      let(:new_metadata_instance) { mocked_metadata_instance }

      it 'changes' do
        new_etag = run(new_metadata_instance, entities)
        expect(new_etag).not_to eq(etag)
      end
    end
  end
end

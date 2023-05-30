# frozen_string_literal: true

RSpec.shared_examples 'ETL::EntityDescriptors' do
  # rubocop:disable Metrics/MethodLength
  def create_json(id, functioning: true, services_functioning: true, empty: false)
    {
      id:,
      entity_id: Faker::Internet.url,
      organization: {
        id: 2000 + id,
        name: Faker::Lorem.sentence
      },
      contacts: [
        {
          id: 6000 + id,
          type: {
            id: 4,
            name: 'technical'
          }
        },
        {
          id: 7000 + id,
          type: {
            id: 3,
            name: 'support'
          }
        }
      ],
      active: true,
      archived: false,
      approved: true,
      functioning:,
      created_at: fr_time(ed_created_at),
      saml: {
        empty:,
        identity_providers: [
          {
            id: 3000 + id,
            functioning: services_functioning
          }
        ],
        service_providers: [
          {
            id: 4000 + id,
            functioning: services_functioning
          }
        ],
        attribute_authorities: [
          {
            id: 5000 + id,
            functioning: services_functioning
          }
        ]
      }
    }
  end
  # rubocop:enable Metrics/MethodLength

  let(:ed_created_at) { Time.zone.at(rand(Time.now.utc.to_i)) }
  let(:entity_descriptor_list) do
    (0...entity_descriptor_count)
      .reduce([]) { |a, e| a << create_json(1000 + e) }
  end
  let(:organization) { create :organization }
  let(:org_data) do
    {
      saml: {
        entity_descriptors:
          (0...entity_descriptor_count)
            .reduce([]) { |a, e| a << create_json(1000 + e) }
      }
    }
  end
  let(:entity_descriptors) { entity_descriptor_list }

  before do
    stub_fr_request(:entity_descriptors)
    allow_any_instance_of(described_class).to receive(:identity_providers)
      .with(kind_of(EntityDescriptor), anything)
    allow_any_instance_of(described_class).to receive(:attribute_authorities)
      .with(kind_of(EntityDescriptor), anything)
    allow_any_instance_of(described_class).to receive(:service_providers)
      .with(kind_of(EntityDescriptor), anything)
  end

  def run
    described_class.new(id: fr_source.id)
                   .entity_descriptors(organization, org_data)
  end

  context 'A non functioning EntityDescriptor' do
    let(:entity_descriptor_count) { 1 }
    let(:entity_descriptor_list) do
      (0...entity_descriptor_count)
        .reduce([]) { |a, e| a << create_json(1000 + e, functioning: false) }
    end

    it 'does not create an EntityDescriptor' do
      expect { run }.not_to(change { EntityDescriptor.count })
    end

    context 'with existing EntityDescriptor reference' do
      subject { EntityDescriptor.last }
      let(:entity_descriptor_list) do
        (0...entity_descriptor_count)
          .reduce([]) { |a, e| a << create_json(1000 + e) }
      end

      before do
        run
        entity_descriptor_list.first[:functioning] = false
        stub_fr_request(:entity_descriptors)
      end

      it 'Deletes the existing EntityDescriptor reference' do
        expect { run }.to change { EntityDescriptor.count }.by(-1)
      end
    end
  end

  context 'An empty EntityDescriptor' do
    let(:entity_descriptor_count) { 1 }
    let(:entity_descriptor_list) do
      (0...entity_descriptor_count)
        .reduce([]) { |a, e| a << create_json(1000 + e, functioning: true, empty: true) }
    end

    it 'does not create an EntityDescriptor' do
      expect { run }.not_to(change { EntityDescriptor.count })
    end

    context 'with existing EntityDescriptor reference' do
      subject { EntityDescriptor.last }
      let(:entity_descriptor_list) do
        (0...entity_descriptor_count)
          .reduce([]) { |a, e| a << create_json(1000 + e) }
      end

      before do
        run
        entity_descriptor_list.first[:saml][:empty] = true
        stub_fr_request(:entity_descriptors)
      end

      it 'Deletes the existing EntityDescriptor reference' do
        expect { run }.to change { EntityDescriptor.count }.by(-1)
      end
    end
  end

  context 'creating an EntityDescriptor' do
    subject { EntityDescriptor.last }
    before do
      run

      # ED requires a role descriptor to be present so we
      # manually inject one for now. Future parts of the FR import flow will
      # link IdP/SP/AA to the parent ED
      create(:idp_sso_descriptor, entity_descriptor: EntityDescriptor.last)

      # ED requires a technical contact to be present so we manually
      # inject one for now. Future parts of the FR import flow will assign
      # their technical contacts to the parent ED
      create(:contact_person, entity_descriptor: EntityDescriptor.last)
    end
    let(:entity_descriptor_count) { 1 }

    verify(created_at: -> { ed_created_at },
           updated_at: -> { truncated_now })

    it 'has entity_id, registration_authority, registration_policy and known_entity with tag' do
      expect({
               entity_id: subject.entity_id.uri,
               registration_authority: subject.registration_info.registration_authority,
               registration_policy_uri: subject.registration_info.registration_policies.first.uri,
               registration_policy_uri_lang: subject.registration_info.registration_policies.first.lang,
               source_tag: subject.known_entity.tags.first.name
             }).to match({
                           entity_id: entity_descriptors.last[:entity_id],
                           registration_authority: fr_source.registration_authority,
                           registration_policy_uri: fr_source.registration_policy_uri,
                           registration_policy_uri_lang: fr_source.registration_policy_uri_lang,
                           source_tag: subject.known_entity.entity_source.source_tag
                         })
    end

    context 'when services functioning is false' do
      let(:entity_descriptor_list) do
        (0...entity_descriptor_count)
          .reduce([]) { |a, e| a << create_json(1000 + e, services_functioning: false) }
      end

      it 'doesnt create a new SingleSignOnService' do
        expect { run }.not_to(change do
                                [
                                  ArtifactResolutionService.count,
                                  SingleLogoutService.count,
                                  ManageNameIdService.count
                                ]
                              end)
      end
    end
  end

  context 'updating an EntityDescriptor' do
    subject { EntityDescriptor.last }
    let(:entity_descriptor_count) { 1 }

    context 'EntityID' do
      let(:updated_entityid) { Faker::Internet.url }
      before do
        run
        entity_descriptor_list.first[:entity_id] = updated_entityid
        stub_fr_request(:entity_descriptors)
      end

      it 'updates the EntityID uri, KnownEntity and federation tag' do
        expect { run }.to change { subject.reload.entity_id.uri }
          .to eq(updated_entityid)
        Timecop.travel(1.second) do
          expect { run }.to(change { subject.reload.known_entity.updated_at })
        end
        expect(subject.known_entity.tags.first.name)
          .to eq(subject.known_entity.entity_source.source_tag)
      end
    end
  end

  context 'entity_descriptor json response' do
    shared_examples 'obj creation' do
      it 'creates EntityDescriptor' do
        expect { run }.to(
          change { EntityDescriptor.count }
            .by(entity_descriptor_count)
        )

        expect { run }.not_to(change { Tag.count })
      end
    end

    context 'single new entity_descriptor' do
      let(:entity_descriptor_count) { 1 }
      include_examples 'obj creation'
    end

    context 'multiple new entity_descriptor' do
      let(:entity_descriptor_count) { rand(2..20) }
      include_examples 'obj creation'
    end

    context 'updating entity_descriptor' do
      let(:entity_descriptor_count) { 1 }
      before { run }

      context 'subsequent requests' do
        let(:entity_descriptor_count) { 0 }
        before { run }
        include_examples 'obj creation'
      end
    end
  end
end

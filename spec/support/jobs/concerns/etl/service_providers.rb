# frozen_string_literal: true

RSpec.shared_examples 'ETL::ServiceProviders' do
  include_examples 'ETL::Common'

  let(:contact_people) do
    contact_instances.map { |cp| contact_person_json(cp) } +
      sirtfi_contact_instances.map { |cp| sirtfi_contact_person_json(cp) }
  end
  def create_json(sp, services_functioning: true)
    {
      id: sp.id,
      display_name: Faker::Lorem.sentence,
      description: description,
      functioning: sp.functioning?,
      created_at: sp_created_at,
      saml: {
        authnrequests_signed: sp.authn_requests_signed,
        assertions_signed: sp.want_assertions_signed,
        attribute_consuming_services:
          sp.attribute_consuming_services.map do |as|
            {
              is_default: as.default,
              names: as.service_names,
              descriptions: as.service_descriptions,
              attributes:
                attribute_instances.map { |ra| requested_attribute_json(ra) }
            }
          end,
        assertion_consumer_services:
          sp.assertion_consumer_services.map do |acs|
            indexed_endpoint_json(acs, functioning: services_functioning)
          end,
        discovery_response_services:
          sp.discovery_response_services.map do |drs|
            indexed_endpoint_json(drs, functioning: services_functioning)
          end,
        sso_descriptor: {
          role_descriptor: {
            protocol_support_enumerations:
              sp.protocol_supports.map { |pse| saml_uri_json(pse) },
            key_descriptors:
              sp.key_descriptors.map { |kd| key_descriptor_json(kd) }
                .push(bad_key_descriptor_json),
            contact_people: contact_people,
            error_url: sp.error_url
          },
          name_id_formats:
            sp.name_id_formats.map { |nidf| saml_uri_json(nidf) },
          artifact_resolution_services:
            sp.artifact_resolution_services.map do |ars|
              indexed_endpoint_json(ars, functioning: services_functioning)
            end,
          single_logout_services:
            sp.single_logout_services.map { |slo| endpoint_json(slo) },
          manage_nameid_services:
            sp.manage_name_id_services.map { |mnids| endpoint_json(mnids) }
        }
      }
    }
  end
  # rubocop:enable

  def requested_attribute_json(ra)
    {
      id: ra[:id],
      name: Faker::Lorem.word,
      is_required: false,
      reason: Faker::Lorem.word,
      approved: ra[:approved],
      specification: ra[:specification] ||= false,
      values: ra[:values]
    }
  end

  def attribute_base_json(a)
    {
      id: a[:id],
      description: a[:description],
      oid: a[:oid],
      name_format: {
        uri: 'urn:oasis:names:tc:SAML:2.0:attrname-format:uri'
      }
    }
  end

  def fr_object(name, id)
    FederationRegistryObject.create(internal_class_name: name,
                                    internal_id: id, fr_id: id)
  end

  def run
    described_class.new(id: fr_source.id)
                   .service_providers(entity_descriptor, ed_data)
  end

  let(:service_provider_instances) do
    create_list(:sp_sso_descriptor, sp_count,
                :with_authn_requests_signed,
                :with_want_assertions_signed,
                :request_attributes,
                :with_ui_info,
                :with_discovery_response_services,
                :with_key_descriptors,
                :with_single_logout_services,
                :with_manage_name_id_services,
                :with_name_id_formats,
                :with_artifact_resolution_services)
  end

  let(:service_providers_list) do
    service_provider_instances.map { |sp| create_json(sp) }
  end

  let(:service_providers) { service_providers_list }

  let(:sp_created_at) { Time.zone.at(rand(Time.now.utc.to_i)) }

  let(:entity_descriptor) { create :entity_descriptor }

  let(:ed_data) do
    {
      saml: {
        service_providers:
          service_provider_instances.map do |sp|
            { id: sp.id, functioning: sp.functioning? }
          end
      }
    }
  end

  let(:attribute_instances) do
    (0...attribute_count).map do |i|
      {
        id: i,
        description: Faker::Lorem.sentence,
        oid: "#{Faker::Number.number(digits: 4)}:" \
             "#{Faker::Number.number(digits: 4)}",
        approved: true,
        values: []
      }
    end.push(
      id: attribute_count,
      description: Faker::Lorem.sentence,
      oid: "#{Faker::Number.number(digits: 4)}:" \
           "#{Faker::Number.number(digits: 4)}",
      approved: true,
      values: [],
      specification: true
    ).push(
      id: attribute_count + 1,
      description: Faker::Lorem.sentence,
      oid: "#{Faker::Number.number(digits: 4)}:" \
           "#{Faker::Number.number(digits: 4)}",
      approved: true,
      values: [{ approved: true, value: Faker::Number.number(digits: 4) },
               { approved: false, value: Faker::Number.number(digits: 3) }],
      specification: true
    ).push(
      id: attribute_count + 2,
      description: Faker::Lorem.sentence,
      oid: "#{Faker::Number.number(digits: 4)}:" \
           "#{Faker::Number.number(digits: 4)}",
      approved: false,
      values: []
    )
  end

  let(:attributes_list) do
    attribute_instances.map { |a| attribute_base_json(a) }
  end

  let(:attributes) { attributes_list }

  before do
    stub_fr_request(:contacts)

    [*contact_instances, *sirtfi_contact_instances]
      .each { |c| fr_object(Contact.name, c.id) }

    stub_fr_request(:attributes)
    stub_fr_request(:service_providers)
  end

  context 'creating an SPSSODescriptor' do
    let(:source_sp) { service_provider_instances.first }
    let(:sp_count) { 1 }
    let(:contact_count) { 2 }
    let(:sirtfi_contact_count) { 2 }
    let(:attribute_count) { 3 }

    subject { SPSSODescriptor.last }

    it 'creates a new instance' do
      expect { run }.to change { SPSSODescriptor.count }.by(sp_count).and(
        change { Tag.count }.by(1)
      ).and(
        change { AttributeConsumingService.count }.by(sp_count)
      )
    end

    context 'With invalid contacts' do
      let(:contact_people) do
        contact_people = contact_instances.map { |cp| contact_person_json(cp) } +
                         sirtfi_contact_instances.map { |cp| sirtfi_contact_person_json(cp) }
        contact_people.each do |contact|
          contact[:type][:name] = :blah
        end
        contact_people
      end

      it 'creates a new AttributeConsumingService ' do
        expect { run }.to(change { AttributeConsumingService.count })
      end
    end

    context 'Without fr contacts' do
      let(:contact_people) do
        contact_people = contact_instances.map { |cp| contact_person_json(cp) } +
                         sirtfi_contact_instances.map { |cp| sirtfi_contact_person_json(cp) }
        contact_people.each do |contact|
          FederationRegistryObject.find(fr_id: contact[:contact][:id], internal_class_name: Contact.dataset.model.name).destroy
        end
        contact_people
      end

      it 'creates a new AttributeConsumingService ' do
        expect { run }.to(change { AttributeConsumingService.count })
      end
    end

    context 'when no AttributeConsumingService to add' do
      let(:service_providers_list) do
        service_provider_instances.map do |sp|
          json = create_json(sp)
          json[:saml][:attribute_consuming_services] = nil
          json
        end
      end

      it 'doesnt create a new AttributeConsumingService ' do
        expect { run }.not_to(change { AttributeConsumingService.count })
      end
    end

    context 'with a solo requestedAttribute requiring specification with no requested value' do
      let(:attribute_instances) do
        [
          id: 0,
          description: Faker::Lorem.sentence,
          oid: "#{Faker::Number.number(digits: 4)}:" \
               "#{Faker::Number.number(digits: 4)}",
          approved: true,
          values: [],
          specification: true
        ]
      end

      it 'does not create a new AttributeConsumingService' do
        expect { run }.not_to(change { AttributeConsumingService.count })
      end
    end

    context 'created instance' do
      before { run }

      it 'is provided with attributes that are not acceptable' do
        expect(attribute_instances.size).to eq(attribute_count + 3)
      end

      it 'requests expected number of attributes' do
        run
        expect(AttributeConsumingService.last.reload.requested_attributes.size)
          .to eq(attribute_count + 1)
      end

      context 'assertion_consumer_services' do
        include_examples 'indexed_endpoint' do
          let(:target) { subject.assertion_consumer_services }
          let(:source) { source_sp.assertion_consumer_services }
        end
      end

      context 'discovery_response_services' do
        include_examples 'indexed_endpoint' do
          let(:target) { subject.discovery_response_services }
          let(:source) { source_sp.discovery_response_services }
        end
      end

      context 'protocol supports' do
        include_examples 'saml_uris' do
          let(:target) { subject.protocol_supports }
          let(:source) { source_sp.protocol_supports }
        end
      end

      context 'key descriptors' do
        include_examples 'key_descriptors' do
          let(:target) { subject.key_descriptors }
          let(:source) { source_sp.key_descriptors }
        end
      end

      context 'contact people' do
        include_examples 'contact_people' do
          let(:target) { subject.entity_descriptor.contact_people }
          let(:source) do
            service_providers
              .first[:saml][:sso_descriptor][:role_descriptor][:contact_people]
              .reject { |cp| cp[:type][:name] == 'Security' }
          end
        end
      end

      context 'nameid formats' do
        include_examples 'saml_uris' do
          let(:target) { subject.name_id_formats }
          let(:source) { source_sp.name_id_formats }
        end
      end

      context 'artifact resolution services' do
        include_examples 'indexed_endpoint' do
          let(:target) { subject.artifact_resolution_services }
          let(:source) { source_sp.artifact_resolution_services }
        end
      end

      context 'single logout services' do
        include_examples 'endpoint' do
          let(:target) { subject.single_logout_services }
          let(:source) { source_sp.single_logout_services }
        end
      end

      context 'manage nameid services' do
        include_examples 'endpoint' do
          let(:target) { subject.manage_name_id_services }
          let(:source) { source_sp.manage_name_id_services }
        end
      end
    end
  end

  context 'updating an SPSSODescriptor' do
    subject { SPSSODescriptor.last }

    let(:sp_count) { 1 }
    let(:contact_count) { 2 }
    let(:sirtfi_contact_count) { 2 }
    let(:attribute_count) { 3 }

    before { run }

    include_examples 'updating an SSODescriptor'
    include_examples 'updating MDUI content'

    it 'uses the existing instance' do
      expect { run }.to(not_change { SPSSODescriptor.count }.and(
        not_change { Tag.count }
      ).and(
        change { subject.reload.assertion_consumer_services }
      ).and(
        change { subject.reload.discovery_response_services }
      ).and(
        change { subject.reload.attribute_consuming_services }
      ))
    end

    context 'when no discovery_response_services not functioning' do
      let(:service_providers_list) do
        service_provider_instances.map do |sp|
          create_json(sp, services_functioning: false)
        end
      end

      it 'doesnt update discovery_response_services' do
        expect { run }.not_to(change { subject.reload.discovery_response_services })
      end
    end
  end
end

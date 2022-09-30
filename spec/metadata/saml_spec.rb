# frozen_string_literal: true

require 'rails_helper'

require 'metadata/saml'

RSpec.describe Metadata::Saml do
  subject do
    Metadata::Saml.new(metadata_instance: metadata_instance)
  end

  let(:federation_identifier) { Faker::Internet.domain_word }
  let(:metadata_name) { "urn:mace:#{federation_identifier}.edu:test" }
  let(:metadata_validity_period) { 1.week }
  let(:entity_descriptors) { entity_source.entity_descriptors }
  let(:hash_algorithm) { 'sha256' }

  let(:metadata_instance) do
    create(:metadata_instance, hash_algorithm: hash_algorithm,
                               name: metadata_name,
                               federation_identifier: federation_identifier,
                               validity_period: metadata_validity_period)
  end

  let(:builder) { subject.builder }
  let(:raw_xml) { builder.to_xml }
  let(:xml) do
    # Pull out xmlns so our tests don't need to specify it everywhere
    # as we expect metadata nodes to live under this namespace by default
    raw_xml.sub!('xmlns="urn:oasis:names:tc:SAML:2.0:metadata"', '')
    Capybara::Node::Simple.new(Nokogiri::XML.parse(raw_xml))
  end

  # Nodes which by schema may validly appear in multiple locations
  let(:all_publication_infos) { '//mdrpi:PublicationInfo' }

  context 'SAML namespaces' do
    include_examples 'SAML namespaces'
  end

  context 'EntitiesDescriptors' do
    let(:entity_source) { create :basic_federation }
    let(:tag) { Faker::Lorem.word }
    let(:all_tagged_known_entities) { KnownEntity.with_all_tags(tag) }

    context 'with only functioning entity descriptors' do
      before { entity_source.known_entities.each { |ke| ke.tag_as(tag) } }
      include_examples 'EntitiesDescriptor xml' do
        it 'has 5 known entities' do
          expect(entity_source.known_entities.size).to eq(5)
        end
      end
    end

    context 'with functioning and non functioning EntityDescriptors' do
      before do
        idp = create(:basic_federation_entity, :idp,
                     entity_source: entity_source)
        idp.entity_descriptor.enabled = false
        idp.entity_descriptor.save

        sp = create(:basic_federation_entity, :sp, entity_source: entity_source)
        sp.entity_descriptor.enabled = false
        sp.entity_descriptor.save

        raw_aa = create(:known_entity, entity_source: entity_source)
        raw_aa.raw_entity_descriptor = create(:raw_entity_descriptor,
                                              known_entity: raw_aa,
                                              enabled: false)
        raw_aa.save

        entity_source.known_entities.each { |ke| ke.tag_as(tag) }
      end

      include_examples 'EntitiesDescriptor xml' do
        it 'has 8 known entities' do
          expect(entity_source.known_entities.size).to eq(8)
        end
      end
    end

    context 'with the same EntityDescriptor from multiple sources' do
      let(:rank) { entity_source.rank + [1, -1].sample }
      let(:external_entity_source) { create :entity_source, rank: rank }
      let(:entity) { entity_source.known_entities.first }
      let(:entity_id) { entity.entity_id }
      let(:enabled) { [true, false].sample }

      before do
        idp = create(:basic_federation_entity, :idp,
                     entity_source: external_entity_source, enabled: enabled)

        idp.entity_descriptor.entity_id.update(uri: entity_id)

        entity_source.known_entities.each { |ke| ke.tag_as(tag) }
        external_entity_source.known_entities.each { |ke| ke.tag_as(tag) }
      end

      let(:external_entity) { external_entity_source.known_entities.first }

      let(:entity_ordered_by_rank) do
        [entity, external_entity].sort_by { |e| e.entity_source.try(:rank) }
      end

      let(:other_entities) do
        entity_source.known_entities.tap { |a| a.delete(entity) }
      end

      describe '#filter_known_entities' do
        let(:other_entities_as_list) { other_entities.map { |e| [e] } }

        it 'returns enabled and disabled entities as lists ordered by rank' do
          expect(subject.filter_known_entities(all_tagged_known_entities))
            .to eq([entity_ordered_by_rank, *other_entities_as_list])
        end
      end

      describe '#known_entity_list' do
        let(:highest_ranked_functioning_entity) do
          entity_ordered_by_rank.find { |e| e.entity_descriptor.functioning? }
        end

        let(:expected_entity_descriptors) do
          [highest_ranked_functioning_entity, *other_entities]
            .map(&:entity_descriptor)
        end

        it 'returns functional entities ordered by rank' do
          result = subject.known_entity_list(all_tagged_known_entities)

          expect(result).to eq(expected_entity_descriptors)
        end
      end

      include_examples 'EntitiesDescriptor xml' do
        it 'has 6 known entities' do
          expect(KnownEntity.with_all_tags(tag).length).to eq(6)
        end
      end
    end
  end

  context 'KeyInfo' do
    let(:key_info) { create :key_info }
    before { subject.key_info(key_info) }
    include_examples 'ds:KeyInfo xml'
  end

  context 'PublisherInfo' do
    let(:entity_source) { create(:basic_federation) }
    let(:entity_descriptor) do
      create(:entity_descriptor, :with_publication_info)
    end
    context 'EntitiesDescriptor' do
      before { subject.publication_info(metadata_instance) }
      include_examples 'mdrpi:PublisherInfo xml' do
        let(:root_node) { metadata_instance }
      end
    end
    context 'EntityDescriptor' do
      before { subject.publication_info(entity_descriptor) }
      include_examples 'mdrpi:PublisherInfo xml' do
        let(:root_node) { entity_descriptor }
      end
    end
  end

  context 'EntityDescriptors' do
    include_examples 'EntityDescriptor xml'
  end

  context 'RawEntityDescriptor' do
    include_examples 'RawEntityDescriptor xml'
  end

  context 'RegistrationInfo' do
    let(:metadata_instance) do
      create(:metadata_instance, :with_registration_info)
    end
    let(:entity_descriptor) { create(:entity_descriptor) }
    context 'EntitiesDescriptor' do
      before { subject.registration_info(metadata_instance) }
      include_examples 'mdrpi:RegistrationInfo xml' do
        let(:root_node) { metadata_instance }
      end
    end
    context 'EntityDescriptor' do
      before { subject.registration_info(entity_descriptor) }
      include_examples 'mdrpi:RegistrationInfo xml' do
        let(:root_node) { entity_descriptor }
      end
    end
  end

  context 'Organizations' do
    let(:organization) do
      create :organization, :with_multiple_organization_languages
    end
    before { subject.organization(organization) }
    include_examples 'Organization xml'
  end

  context 'ContactPersons' do
    let(:contact_person) { create :contact_person }
    before { subject.contact_person(contact_person) }
    include_examples 'ContactPerson xml'
  end

  context 'SIRTFI ContactPersons' do
    let(:sirtfi_contact_person) { create(:sirtfi_contact_person) }
    before { subject.sirtfi_contact_person(sirtfi_contact_person) }
    include_examples 'SIRTFI ContactPerson xml'
  end

  context 'EntityAttributes' do
    let(:entity_attribute) { create :mdattr_entity_attribute }
    before { subject.entity_attribute(entity_attribute) }
    include_examples 'mdattr:EntityAttribute xml'
  end

  context 'Attributes and AttributeValues' do
    let(:attribute) { create :attribute }
    before { subject.attribute(attribute) }
    include_examples 'saml:Attribute xml'
  end

  context 'RoleDescriptors' do
    include_examples 'RoleDescriptor xml' do
      let(:role_descriptor_path) { '/RoleDescriptor' }
      let(:parent_node) { :role_descriptor }
      let(:role_descriptor) { create parent_node }
      before do
        subject.root.RoleDescriptor(subject.ns) do |rd|
          subject.role_descriptor(role_descriptor, rd)
        end
      end
    end
  end

  context 'KeyDescriptors' do
    let(:key_descriptor) { create :key_descriptor }
    before { subject.key_descriptor(key_descriptor) }
    include_examples 'KeyDescriptor xml'
  end

  context 'SSODescriptors' do
    include_examples 'SSODescriptor xml' do
      # In reality this XML path is not valid, but utilising it
      # here makes for finer grained tests
      let(:sso_descriptor_path) { '/SSODescriptor' }
      let(:parent_node) { :sso_descriptor }
      let(:sso_descriptor) { create parent_node }
      before do
        subject.root.SSODescriptor(subject.ns) do |ssod|
          subject.sso_descriptor(sso_descriptor, ssod)
        end
      end
    end
  end

  context 'Endpoint' do
    include_examples 'Endpoint xml' do
      let(:endpoint_path) { '/Endpoint' }
      let(:parent_node) { :_endpoint }
      let(:endpoint) { create parent_node }
      before do
        subject.root.Endpoint(subject.ns) do |ep|
          subject.endpoint(endpoint, ep)
        end
      end
    end
  end

  context 'IndexedEndpoint' do
    include_examples 'IndexedEndpoint xml' do
      let(:endpoint_path) { '/IndexedEndpoint' }
      let(:parent_node) { :_indexed_endpoint }
      let(:endpoint) { create parent_node }
      before do
        subject.root.IndexedEndpoint(subject.ns) do |ep|
          subject.indexed_endpoint(endpoint, ep)
        end
      end
    end
  end

  context 'ArtifactResolutionService' do
    include_examples 'IndexedEndpoint xml' do
      let(:endpoint_path) { '/ArtifactResolutionService' }
      let(:parent_node) { :artifact_resolution_service }
      let(:endpoint) { create parent_node }
      before { subject.artifact_resolution_service(endpoint) }
    end
  end

  context 'SingleLogoutService' do
    include_examples 'Endpoint xml' do
      let(:endpoint_path) { '/SingleLogoutService' }
      let(:parent_node) { :single_logout_service }
      let(:endpoint) { create parent_node }
      before { subject.single_logout_service(endpoint) }
    end
  end

  context 'ManageNameIDService' do
    include_examples 'Endpoint xml' do
      let(:endpoint_path) { '/ManageNameIDService' }
      let(:parent_node) { :manage_name_id_service }
      let(:endpoint) { create parent_node }
      before { subject.manage_name_id_service(endpoint) }
    end
  end

  context 'IDPSSODescriptor' do
    let(:idp_sso_descriptor_path) { '/IDPSSODescriptor' }

    context 'Parent nodes and abstract types' do
      let(:parent_node) { :idp_sso_descriptor }

      context 'RoleDescriptorType' do
        let(:role_descriptor_path) { idp_sso_descriptor_path }
        let(:role_descriptor) { create parent_node }
        before { subject.idp_sso_descriptor(role_descriptor) }
        include_examples 'RoleDescriptor xml'
      end

      context 'SSODescriptorType' do
        let(:sso_descriptor_path) { idp_sso_descriptor_path }
        let(:sso_descriptor) { create parent_node }
        before { subject.idp_sso_descriptor(sso_descriptor) }
        include_examples 'SSODescriptor xml'
      end
    end

    context 'IDPSSODescriptorType' do
      let(:idp_sso_descriptor) { create :idp_sso_descriptor }
      before { subject.idp_sso_descriptor(idp_sso_descriptor) }
      include_examples 'IDPSSODescriptor xml'
    end
  end

  context 'SingleSignOnService' do
    include_examples 'Endpoint xml' do
      let(:endpoint_path) { '/SingleSignOnService' }
      let(:parent_node) { :single_sign_on_service }
      let(:endpoint) { create parent_node }
      before { subject.single_sign_on_service(endpoint) }
    end
  end

  context 'NameIDMappingService' do
    include_examples 'Endpoint xml' do
      let(:endpoint_path) { '/NameIDMappingService' }
      let(:parent_node) { :name_id_mapping_service }
      let(:endpoint) { create parent_node }
      before { subject.name_id_mapping_service(endpoint) }
    end
  end

  context 'AssertionIDRequestService' do
    include_examples 'Endpoint xml' do
      let(:endpoint_path) { '/AssertionIDRequestService' }
      let(:parent_node) { :assertion_id_request_service }
      let(:endpoint) { create parent_node }
      before { subject.assertion_id_request_service(endpoint) }
    end
  end

  context 'SPSSODescriptor' do
    let(:sp_sso_descriptor_path) { '/SPSSODescriptor' }

    context 'Parent nodes and abstract types' do
      let(:parent_node) { :sp_sso_descriptor }

      context 'RoleDescriptorType' do
        let(:role_descriptor_path) { sp_sso_descriptor_path }
        let(:role_descriptor) { create parent_node }
        before { subject.sp_sso_descriptor(role_descriptor) }
        include_examples 'RoleDescriptor xml'
      end

      context 'SSODescriptorType' do
        let(:sso_descriptor_path) { sp_sso_descriptor_path }
        let(:sso_descriptor) { create parent_node }
        before { subject.sp_sso_descriptor(sso_descriptor) }
        include_examples 'SSODescriptor xml'
      end
    end

    context 'SPSSODescriptorType' do
      let(:sp_sso_descriptor) { create :sp_sso_descriptor }
      before { subject.sp_sso_descriptor(sp_sso_descriptor) }
      include_examples 'SPSSODescriptor xml'
    end
  end

  context 'AssertionConsumerService' do
    include_examples 'IndexedEndpoint xml' do
      let(:endpoint_path) { '/AssertionConsumerService' }
      let(:parent_node) { :assertion_consumer_service }
      let(:endpoint) { create parent_node }
      before { subject.assertion_consumer_service(endpoint) }
    end
  end

  context 'AttributeConsumingService' do
    let(:attribute_consuming_service_path) { '/AttributeConsumingService' }
    let(:attribute_consuming_service) { create :attribute_consuming_service }
    before { subject.attribute_consuming_service(attribute_consuming_service) }
    include_examples 'AttributeConsumingService xml'
  end

  context 'RequestedAttributes' do
    let(:requested_attribute_path) { '/RequestedAttribute' }
    let(:requested_attribute) { create :requested_attribute }
    before { subject.requested_attribute(requested_attribute) }
    include_examples 'RequestedAttribute xml'
  end

  context 'AttributeAuthorityDescriptor' do
    let(:attribute_authority_descriptor_path) do
      '/AttributeAuthorityDescriptor'
    end

    context 'RoleDescriptorType' do
      let(:parent_node) { :attribute_authority_descriptor }
      let(:role_descriptor_path) { attribute_authority_descriptor_path }
      let(:role_descriptor) { create parent_node }
      before { subject.attribute_authority_descriptor(role_descriptor) }
      include_examples 'RoleDescriptor xml'
    end

    context 'AttributeAuthorityDescriptorType' do
      let(:attribute_authority_descriptor) do
        create :attribute_authority_descriptor
      end
      before do
        subject.attribute_authority_descriptor(attribute_authority_descriptor)
      end
      include_examples 'AttributeAuthorityDescriptor xml'
    end
  end

  context 'AttributeService' do
    include_examples 'Endpoint xml' do
      let(:endpoint_path) { '/AttributeService' }
      let(:parent_node) { :attribute_service }
      let(:endpoint) { create parent_node }
      before { subject.attribute_service(endpoint) }
    end
  end

  context 'mdui:UIInfo' do
    let(:ui_info) { create :mdui_ui_info }
    before { subject.ui_info(ui_info) }
    include_examples 'mdui:UIInfo xml'
  end

  context 'mdui:DiscoHints' do
    let(:disco_hints) { create :mdui_disco_hint, :with_content }
    before { subject.disco_hints(disco_hints) }
    include_examples 'mdui:DiscoHints xml'
  end

  context 'shibmd:Scope' do
    include_examples 'shibmd:Scope xml'
  end

  context 'ds:Signature' do
    let(:entities) do
      [create(:idp_sso_descriptor).entity_descriptor.known_entity]
    end
    before { subject.entities_descriptor(entities) }
    include_examples 'ds:Signature xml' do
      let(:root_node) { 'EntitiesDescriptor' }
    end
  end

  context 'ds:Signature Root EntityDescriptor' do
    let(:entity) { create(:idp_sso_descriptor).entity_descriptor }
    before { subject.root_entity_descriptor(entity.known_entity) }
    include_examples 'ds:Signature xml' do
      let(:root_node) { 'EntityDescriptor' }
    end
  end

  context 'ds:Signature Root RawEntityDescriptor' do
    let(:ed_xml) do
      <<~ENTITY
        <EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata"
            entityID="https://test.example.com/idp/shibboleth"
            xmlns:mdrpi="urn:oasis:names:tc:SAML:metadata:rpi">
          <Extensions>
            <mdrpi:PublicationInfo publisher="http://luettgen.com/maximilian"
              creationInstant="2015-07-06T22:33:00Z"
              publicationId="hoppekuhn20150706223300">
              <mdrpi:UsagePolicy xml:lang="en">
                http://www.edugain.org/policy/metadata-tou_1_0.txt
              </mdrpi:UsagePolicy>
            </mdrpi:PublicationInfo>
            <mdrpi:RegistrationInfo
              registrationAuthority="http://sauerheidenreich.net/einar_upton"
              registrationInstant="2015-07-06T22:33:00Z">
              <mdrpi:RegistrationPolicy xml:lang="en">
                http://trantow.info/ella
              </mdrpi:RegistrationPolicy>
            </mdrpi:RegistrationInfo>
          </Extensions>
          <AttributeAuthorityDescriptor
              protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
            <AttributeService
                Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
                Location="https://example.com/idp/profile/AttributeQuery/SOAP"/>
          </AttributeAuthorityDescriptor>
        </EntityDescriptor>
      ENTITY
    end

    let(:entity) { create(:raw_entity_descriptor, xml: ed_xml) }
    before { subject.root_entity_descriptor(entity.known_entity) }
    include_examples 'ds:Signature xml' do
      let(:root_node) { 'EntityDescriptor' }
    end
  end
end

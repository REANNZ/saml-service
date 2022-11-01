# frozen_string_literal: true

RSpec.shared_examples 'EntitiesDescriptor xml' do
  let(:add_ca_keys) { false }
  let(:add_registration_info) { false }
  let(:add_entity_attributes) { false }
  let(:namespaces) { Nokogiri::XML.parse(raw_xml).collect_namespaces }

  let(:entities_descriptor_path) { '/EntitiesDescriptor' }
  let(:extensions_path) { "#{entities_descriptor_path}/Extensions" }
  let(:registration_info_path) { "#{extensions_path}/mdrpi:RegistrationInfo" }
  let(:entity_attributes_path) { "#{extensions_path}/mdattr:EntityAttributes" }

  let(:entity_descriptor_path) do
    "#{entities_descriptor_path}/EntityDescriptor"
  end
  let(:child_entities_descriptors_path) do
    '/EntitiesDescriptor/EntitiesDescriptor'
  end

  before :each do
    create_list(:ca_key_info, 2, metadata_instance: metadata_instance) if add_ca_keys
    create(:mdrpi_registration_info, metadata_instance: metadata_instance) if add_registration_info
    create(:mdattr_entity_attribute, metadata_instance: metadata_instance) if add_entity_attributes
  end

  context 'Root EntitiesDescriptor' do
    before { subject.entities_descriptor(KnownEntity.with_all_tags(tag)) }
    include_examples 'shibmd:KeyAuthority xml'
    include_examples 'md:EntitiesDescriptor xml'

    it 'defines namespaces and mdrpi:PublisherInfo' do
      expect(namespaces).to eq(Metadata::Saml::NAMESPACES)
      expect(xml).to have_xpath(all_publication_infos, count: 1)
    end

    context 'attributes' do
      let(:node) { xml.find(:xpath, entities_descriptor_path) }

      around { |example| Timecop.freeze { example.run } }

      it 'sets ID, name and validuntil' do
        expect(node['ID']).to eq(subject.instance_id)
          .and start_with(federation_identifier)
        expect(node['Name']).to eq(metadata_name)
        expect(node['validUntil'])
          .to eq((Time.now.utc + metadata_validity_period).xmlschema)
      end
    end
  end
end

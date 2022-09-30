# frozen_string_literal: true

RSpec.shared_examples 'RawEntityDescriptor xml' do
  let(:ed_xml) do
    <<~ENTITY
      <EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata"
          entityID="https://test.example.com/idp/shibboleth">
        <AttributeAuthorityDescriptor
            protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
          <AttributeService
              Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
              Location="https://example.com/idp/profile/AttributeQuery/SOAP"/>
        </AttributeAuthorityDescriptor>
      </EntityDescriptor>
    ENTITY
  end

  let(:raw_entity_descriptor) { create(:raw_entity_descriptor, xml: ed_xml) }
  let(:known_entity) { raw_entity_descriptor.known_entity }
  let(:entity_source) { known_entity.entity_source }
  let(:entity_descriptor_path) { '/EntityDescriptor' }

  context 'Root EntityDescriptor' do
    before { subject.root_entity_descriptor(known_entity) }

    context 'attributes' do
      let(:node) { xml.find(:xpath, entity_descriptor_path) }

      around { |example| Timecop.freeze { example.run } }

      it 'sets ID' do
        expect(node['ID']).to eq(subject.instance_id)
          .and start_with(federation_identifier)
      end
      it 'sets validUntil' do
        expect(node['validUntil'])
          .to eq((Time.now.utc + metadata_validity_period).xmlschema)
      end
    end
  end

  context 'EntityDescriptor' do
    before { subject.entities_descriptor([known_entity]) }

    it 'is included in the output' do
      xpath = '//EntityDescriptor' \
              '[@entityID="https://test.example.com/idp/shibboleth"]'
      expect(xml).to have_xpath(xpath)
    end
  end
end

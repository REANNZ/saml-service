# frozen_string_literal: true

RSpec.shared_examples 'EntityDescriptor xml' do
  let(:entity_descriptor) { create :entity_descriptor, :with_technical_contact }
  let(:known_entity) { entity_descriptor.known_entity }
  let(:entity_descriptor_path) { '/EntityDescriptor' }
  let(:extensions_path) { "#{entity_descriptor_path}/Extensions" }
  let(:registration_info_path) { "#{extensions_path}/mdrpi:RegistrationInfo" }
  let(:entity_attributes_path) { "#{extensions_path}/mdattr:EntityAttributes" }
  let(:idp_path) { "#{entity_descriptor_path}/IDPSSODescriptor" }
  let(:sp_path) { "#{entity_descriptor_path}/SPSSODescriptor" }
  let(:aad_path) { "#{entity_descriptor_path}/AttributeAuthorityDescriptor" }
  let(:organization_path) { "#{entity_descriptor_path}/Organization" }
  let(:technical_contact_path) do
    "#{entity_descriptor_path}/ContactPerson[@contactType='technical']"
  end

  let(:create_idp) { false }
  let(:create_sp) { false }
  let(:create_aa) { false }
  let(:create_non_functioning_idp) { false }
  let(:create_non_functioning_aa) { false }
  let(:create_non_functioning_sp) { false }
  let(:add_entity_attributes) { false }

  before do
    create(:idp_sso_descriptor, entity_descriptor: entity_descriptor) if create_idp
    if create_non_functioning_idp
      create(:idp_sso_descriptor, entity_descriptor: entity_descriptor,
                                  enabled: false)
    end
    create(:sp_sso_descriptor, entity_descriptor: entity_descriptor) if create_sp
    if create_aa
      create(:attribute_authority_descriptor,
             entity_descriptor: entity_descriptor)
    end
    if create_non_functioning_aa
      create(:attribute_authority_descriptor,
             entity_descriptor: entity_descriptor, enabled: false)
    end
    if create_non_functioning_sp
      create(:sp_sso_descriptor, entity_descriptor: entity_descriptor,
                                 enabled: false)
    end
    create(:mdattr_entity_attribute, entity_descriptor: entity_descriptor) if add_entity_attributes
  end

  RSpec.shared_examples 'md:EntityDescriptor xml' do
    let(:create_idp) { true } # Ensure ED is valid to pass #functioning?
    it 'is created' do
      expect(xml).to have_xpath(entity_descriptor_path)
    end

    context 'attributes' do
      let(:node) { xml.find(:xpath, entity_descriptor_path) }
      it 'has correct entityID' do
        expect(node['entityID']).to eq(entity_descriptor.entity_id.uri)
      end
    end

    context 'Extensions' do
      it 'creates RegistrationInfo node' do
        expect(xml).to have_xpath(registration_info_path, count: 1)
      end

      context 'with EntityAttributes' do
        let(:add_entity_attributes) { true }
        it 'creates EntityAttributes node' do
          expect(xml).to have_xpath(entity_attributes_path, count: 1)
        end
      end
      context 'without EntityAttributes' do
        it 'does not create EntityAttributes node' do
          expect(xml).to have_xpath(entity_attributes_path, count: 0)
        end
      end
    end

    context 'RoleDescriptors' do
      context 'IDPSSODescriptor' do
        it 'creates IDPSSODescriptor node' do
          expect(xml).to have_xpath(idp_path, count: 1)
        end
      end

      context 'SPSSODescriptor' do
        let(:create_idp) { false }
        let(:create_sp) { true }
        it 'creates SPSSODescriptor node' do
          expect(xml).to have_xpath(sp_path, count: 1)
        end
      end

      context 'AttributeAuthorityDescriptor' do
        let(:create_idp) { false }
        let(:create_aa) { true }
        it 'creates AttributeAuthorityDescriptor node' do
          expect(xml).to have_xpath(aad_path, count: 1)
        end
      end

      context 'IDPSSODescriptor and AttributeAuthorityDescriptor pairing' do
        let(:create_idp) { true }
        let(:create_aa) { true }
        it 'creates IDPSSODescriptor node' do
          expect(xml).to have_xpath(idp_path, count: 1)
        end
        it 'creates AttributeAuthorityDescriptor node' do
          expect(xml).to have_xpath(aad_path, count: 1)
        end
      end

      context 'IdP that are not functioning' do
        let(:create_idp) { true }
        let(:create_non_functioning_idp) { true }

        it 'only uses functioning IDPSSODescriptor node' do
          expect(entity_descriptor.idp_sso_descriptors.count).to eq(2)
          expect(xml).to have_xpath(idp_path, count: 1)
        end
      end

      context 'AA that are not functioning' do
        let(:create_aa) { true }
        let(:create_non_functioning_aa) { true }

        it 'only uses functioning AADescriptor node' do
          expect(entity_descriptor.attribute_authority_descriptors.count)
            .to eq(2)
          expect(xml).to have_xpath(aad_path, count: 1)
        end
      end

      context 'SP that are not functioning' do
        let(:create_sp) { true }
        let(:create_non_functioning_sp) { true }

        it 'only uses functioning SPSSODescriptor node' do
          expect(entity_descriptor.sp_sso_descriptors.count).to eq(2)
          expect(xml).to have_xpath(sp_path, count: 1)
        end
      end
    end

    it 'creates an Organization' do
      expect(xml).to have_xpath(organization_path, count: 1)
    end
    it 'creates a technical contact' do
      expect(xml).to have_xpath(technical_contact_path, count: 1)
    end
  end

  context 'Root EntityDescriptor' do
    before { subject.root_entity_descriptor(known_entity) }
    include_examples 'md:EntityDescriptor xml'

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

    context 'Extensions' do
      it 'creates a mdrpi:PublisherInfo' do
        expect(xml).to have_xpath(all_publication_infos, count: 1)
      end
    end
  end

  context 'Root EntityDescriptor - non functioning' do
    before do
      entity_descriptor.enabled = false
      subject.root_entity_descriptor(known_entity)
    end

    it 'is not created' do
      expect(xml).not_to have_xpath(entity_descriptor_path)
    end
  end

  context 'EntityDescriptor' do
    before { subject.entity_descriptor(entity_descriptor) }
    include_examples 'md:EntityDescriptor xml'

    context 'attributes' do
      let(:node) { xml.find(:xpath, entity_descriptor_path) }

      it 'sets ID' do
        expect(node['ID']).to be_falsey
      end
      it 'sets validUntil' do
        expect(node['validUntil']).to be_falsey
      end
    end

    context 'Extensions' do
      it 'does not create mdrpi:PublisherInfo' do
        expect(xml).to have_xpath(all_publication_infos, count: 0)
      end
    end
  end
end

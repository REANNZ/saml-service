# frozen_string_literal: true

RSpec.shared_examples 'AttributeAuthorityDescriptor xml' do
  let(:attribute_service_path) do
    "#{attribute_authority_descriptor_path}/AttributeService"
  end
  let(:assertion_id_request_service_path) do
    "#{attribute_authority_descriptor_path}/AssertionIDRequestService"
  end
  let(:name_id_format_path) do
    "#{attribute_authority_descriptor_path}/NameIDFormat"
  end
  let(:attribute_profile_path) do
    "#{attribute_authority_descriptor_path}/AttributeProfile"
  end
  let(:attribute_path) do
    "#{attribute_authority_descriptor_path}/saml:Attribute"
  end

  it 'is created' do
    expect(xml).to have_xpath(attribute_authority_descriptor_path)
  end

  context 'AttributeServices' do
    it 'is rendered' do
      expect(xml).to have_xpath(attribute_service_path, count: 1)
    end

    context 'multiple endpoints' do
      let(:attribute_authority_descriptor) do
        create :attribute_authority_descriptor,
               :with_multiple_attribute_services
      end
      it 'renders all' do
        expect(xml).to have_xpath(attribute_service_path, count: 3)
      end
    end
  end

  context 'AssertionIDRequestServices' do
    context 'when not populated' do
      it 'is not rendered' do
        expect(xml).not_to have_xpath(assertion_id_request_service_path)
      end
    end
    context 'when populated' do
      let(:attribute_authority_descriptor) do
        create :attribute_authority_descriptor,
               :with_multiple_assertion_id_request_services
      end
      it 'is rendered' do
        expect(xml).to have_xpath(assertion_id_request_service_path, count: 2)
      end
    end
  end

  context 'NameIDFormats' do
    context 'when not populated' do
      it 'is not rendered' do
        expect(xml).not_to have_xpath(name_id_format_path)
      end
    end
    context 'when populated' do
      let(:attribute_authority_descriptor) do
        create :attribute_authority_descriptor,
               :with_multiple_name_id_formats
      end
      let(:node) { xml.first(:xpath, name_id_format_path) }
      it 'is rendered and has expected value' do
        expect(xml).to have_xpath(name_id_format_path, count: 2)
        expect(node.text)
          .to eq(attribute_authority_descriptor.name_id_formats.first.uri)
      end
    end
  end

  context 'AttributeProfiles' do
    context 'when not populated' do
      it 'is not rendered' do
        expect(xml).not_to have_xpath(attribute_profile_path)
      end
    end
    context 'when populated' do
      let(:attribute_authority_descriptor) do
        create :attribute_authority_descriptor,
               :with_multiple_attribute_profiles
      end
      let(:node) { xml.first(:xpath, attribute_profile_path) }
      it 'is rendered and has expected value' do
        expect(xml).to have_xpath(attribute_profile_path, count: 2)
        expect(node.text)
          .to eq(attribute_authority_descriptor.attribute_profiles.first.uri)
      end
    end
  end

  context 'Attributes' do
    context 'when not populated' do
      it 'is not rendered' do
        expect(xml).not_to have_xpath(attribute_path)
      end
    end
    context 'when populated' do
      let(:attribute_authority_descriptor) do
        create :attribute_authority_descriptor,
               :with_multiple_attributes
      end
      let(:node) { xml.first(:xpath, attribute_path) }
      it 'is rendered and has expected value' do
        expect(xml).to have_xpath(attribute_path, count: 2)
        expect(node['Name'])
          .to eq(attribute_authority_descriptor.attributes.first.name)
      end
    end
  end
end

# frozen_string_literal: true

RSpec.shared_examples 'IDPSSODescriptor xml' do
  let(:single_sign_on_service_path) do
    "#{idp_sso_descriptor_path}/SingleSignOnService"
  end
  let(:name_id_mapping_service_path) do
    "#{idp_sso_descriptor_path}/NameIDMappingService"
  end
  let(:assertion_id_request_service_path) do
    "#{idp_sso_descriptor_path}/AssertionIDRequestService"
  end
  let(:attribute_profile_path) do
    "#{idp_sso_descriptor_path}/AttributeProfile"
  end
  let(:attribute_path) do
    "#{idp_sso_descriptor_path}/saml:Attribute"
  end
  let(:mdui_disco_hints_path) do
    "#{idp_sso_descriptor_path}/Extensions/mdui:DiscoHints"
  end

  it 'is created, no WantAuthnRequestsSigned, no NameIDMappingServices,' \
     'no AssertionIDRequestServices, no AttributeProfiles, no mdui:DiscoHints' do
    expect(xml).to have_xpath(idp_sso_descriptor_path)
    expect(node['WantAuthnRequestsSigned']).to be_falsey
    expect(xml).to have_xpath(single_sign_on_service_path, count: 1)
    expect(xml).not_to have_xpath(name_id_mapping_service_path)
    expect(xml).not_to have_xpath(assertion_id_request_service_path)
    expect(xml).not_to have_xpath(attribute_profile_path)
    expect(xml).not_to have_xpath(attribute_path)
    expect(xml).not_to have_xpath(mdui_disco_hints_path)
  end

  let(:node) { xml.first(:xpath, idp_sso_descriptor_path) }

  context 'SingleSignOnServices multiple endpoints' do
    let(:idp_sso_descriptor) do
      create :idp_sso_descriptor, :with_multiple_single_sign_on_services
    end
    it 'renders all' do
      expect(xml).to have_xpath(single_sign_on_service_path, count: 3)
    end
  end

  context 'NameIDMappingServices when populated' do
    let(:idp_sso_descriptor) do
      create :idp_sso_descriptor, :with_name_id_mapping_services
    end
    it 'is rendered' do
      expect(xml).to have_xpath(name_id_mapping_service_path, count: 2)
    end
  end

  context 'AssertionIDRequestServices when populated' do
    let(:idp_sso_descriptor) do
      create :idp_sso_descriptor, :with_assertion_id_request_services
    end
    it 'is rendered' do
      expect(xml).to have_xpath(assertion_id_request_service_path, count: 2)
    end
  end

  context 'AttributeProfiles when populated' do
    let(:node) { xml.first(:xpath, attribute_profile_path) }
    let(:idp_sso_descriptor) do
      create :idp_sso_descriptor, :with_attribute_profiles
    end
    it 'is rendered' do
      expect(xml).to have_xpath(attribute_profile_path, count: 2)
      expect(node.text).to eq(idp_sso_descriptor.attribute_profiles.first.uri)
    end
  end

  context 'Attributes when populated' do
    let(:idp_sso_descriptor) do
      create :idp_sso_descriptor, :with_attributes
    end
    it 'is rendered' do
      expect(xml).to have_xpath(attribute_path, count: 2)
    end
  end

  context 'mdui:DiscoHints when populated' do
    let(:idp_sso_descriptor) do
      create :idp_sso_descriptor, :with_disco_hints
    end
    it 'is rendered' do
      expect(xml).to have_xpath(mdui_disco_hints_path)
    end
  end
end

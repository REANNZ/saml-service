# frozen_string_literal: true

RSpec.shared_examples 'SSODescriptor xml' do
  let(:artifact_resolution_service_path) do
    "#{sso_descriptor_path}/ArtifactResolutionService"
  end
  let(:single_logout_service_path) do
    "#{sso_descriptor_path}/SingleLogoutService"
  end
  let(:manage_name_id_service_path) do
    "#{sso_descriptor_path}/ManageNameIDService"
  end
  let(:name_id_format_path) do
    "#{sso_descriptor_path}/NameIDFormat"
  end

  it 'is created without sso, name_id and artifact resolution' do
    expect(xml).to have_xpath(sso_descriptor_path)
    expect(xml).not_to have_xpath(artifact_resolution_service_path)
    expect(xml).not_to have_xpath(single_logout_service_path)
    expect(xml).not_to have_xpath(manage_name_id_service_path)
    expect(xml).not_to have_xpath(name_id_format_path)
  end

  context 'ArtifactResolutionService when populated' do
    let(:sso_descriptor) do
      create parent_node, :with_artifact_resolution_services
    end
    it 'is rendered' do
      expect(xml).to have_xpath(artifact_resolution_service_path, count: 2)
    end
  end

  context 'SingleLogoutService when populated' do
    let(:sso_descriptor) do
      create parent_node, :with_single_logout_services
    end
    it 'is rendered' do
      expect(xml).to have_xpath(single_logout_service_path, count: 2)
    end
  end

  context 'ManageNameIDService when populated' do
    let(:sso_descriptor) do
      create parent_node, :with_manage_name_id_services
    end
    it 'is rendered' do
      expect(xml).to have_xpath(manage_name_id_service_path, count: 2)
    end
  end

  context 'NameIDFormat when populated' do
    let(:node) { xml.first(:xpath, name_id_format_path) }
    let(:sso_descriptor) do
      create parent_node, :with_name_id_formats
    end
    it 'is rendered with nameid' do
      expect(xml).to have_xpath(name_id_format_path, count: 2)
      expect(node.text).to eq(sso_descriptor.name_id_formats.first.uri)
    end
  end
end

# frozen_string_literal: true

RSpec.shared_examples 'Organization xml' do
  let(:organization_path) { '/Organization' }
  let(:organization_name_path) { "#{organization_path}/OrganizationName" }
  let(:organization_display_name_path) do
    "#{organization_path}/OrganizationDisplayName"
  end
  let(:organization_url_path) { "#{organization_path}/OrganizationURL" }

  it 'is created' do
    expect(xml).to have_xpath(organization_path, count: 1)
  end

  context 'OrganizationName' do
    let(:node) { xml.first(:xpath, organization_name_path) }

    it 'is created, lang and text' do
      expect(xml).to have_xpath(organization_name_path, count: 2)
      expect(node['xml:lang'])
        .to eq(organization.organization_names.first.lang)
      expect(node.text).to eq(organization.organization_names.first.value)
    end
  end

  context 'OrganizationDisplayName' do
    let(:node) { xml.first(:xpath, organization_display_name_path) }

    it 'is created, lang and value' do
      expect(xml).to have_xpath(organization_display_name_path, count: 2)
      expect(node['xml:lang'])
        .to eq(organization.organization_display_names.first.lang)
      expect(node.text)
        .to eq(organization.organization_display_names.first.value)
    end
  end

  context 'OrganizationURL' do
    let(:node) { xml.first(:xpath, organization_url_path) }

    it 'is created, lang and uri' do
      expect(xml).to have_xpath(organization_url_path, count: 2)
      expect(node['xml:lang'])
        .to eq(organization.organization_urls.first.lang)
      expect(node.text)
        .to eq(organization.organization_urls.first.uri)
    end
  end
end

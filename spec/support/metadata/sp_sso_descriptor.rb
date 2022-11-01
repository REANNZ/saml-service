# frozen_string_literal: true

RSpec.shared_examples 'SPSSODescriptor xml' do
  let(:assertion_consumer_service_path) do
    "#{sp_sso_descriptor_path}/AssertionConsumerService"
  end

  let(:attribute_consuming_service_path) do
    "#{sp_sso_descriptor_path}/AttributeConsumingService"
  end

  let(:idpdisc_discovery_response_path) do
    "#{sp_sso_descriptor_path}/Extensions/idpdisc:DiscoveryResponse"
  end

  it 'is created' do
    expect(xml).to have_xpath(sp_sso_descriptor_path)
    expect(xml).to have_xpath(assertion_consumer_service_path, count: 1)
    expect(xml).not_to have_xpath(attribute_consuming_service_path)
    expect(xml).not_to have_xpath(idpdisc_discovery_response_path)
  end

  context 'attributes' do
    let(:node) { xml.first(:xpath, sp_sso_descriptor_path) }

    it 'are not rendered' do
      expect(node['AuthnRequestsSigned']).to be_falsey
      expect(node['WantAssertionsSigned']).to be_falsey
    end
  end

  context 'AssertionConsumerService multiple endpoints' do
    let(:sp_sso_descriptor) do
      create :sp_sso_descriptor, :with_multiple_assertion_consumer_services
    end
    it 'renders all' do
      expect(xml).to have_xpath(assertion_consumer_service_path, count: 3)
    end
  end

  context 'AttributeConsumingService when populated' do
    let(:sp_sso_descriptor) do
      create :sp_sso_descriptor, :with_attribute_consuming_services
    end
    it 'is rendered' do
      expect(xml).to have_xpath(attribute_consuming_service_path, count: 2)
    end
  end

  context 'idpdisc:DiscoveryResponse when populated' do
    let(:sp_sso_descriptor) do
      create :sp_sso_descriptor, :with_discovery_response_services
    end
    it 'is rendered' do
      expect(xml).to have_xpath(idpdisc_discovery_response_path, count: 1)
    end
  end
end

# frozen_string_literal: true

RSpec.shared_examples 'AttributeConsumingService xml' do
  let(:service_name_path) { "#{attribute_consuming_service_path}/ServiceName" }

  let(:service_description_path) do
    "#{attribute_consuming_service_path}/ServiceDescription"
  end

  let(:requested_attribute_path) do
    "#{attribute_consuming_service_path}/RequestedAttribute"
  end
  it 'is created' do
    expect(xml).to have_xpath(attribute_consuming_service_path)
    expect(xml).to have_xpath(requested_attribute_path)
  end

  context 'attributes' do
    let(:node) { xml.first(:xpath, attribute_consuming_service_path) }

    context 'index' do
      it 'is rendered and has expected value' do
        expect(node['index']).to eq(attribute_consuming_service.index.to_s)
        expect(node['isDefault'])
          .to eq(attribute_consuming_service.default.to_s)
      end
    end
  end

  context 'ServiceNames' do
    let(:node) { xml.first(:xpath, service_name_path) }
    it 'is created' do
      expect(xml).to have_xpath(service_name_path)
    end

    context 'attributes lang' do
      it 'is rendered' do
        expect(node['xml:lang'])
          .to eq(attribute_consuming_service.service_names.first.lang)
      end
    end

    it 'has expected value' do
      expect(node.text)
        .to eq(attribute_consuming_service.service_names.first.value)
    end

    context 'multiple names' do
      let(:attribute_consuming_service) do
        create :attribute_consuming_service, :with_multiple_service_names
      end
      it 'renders multiple' do
        expect(xml).to have_xpath(service_name_path, count: 3)
      end
    end
  end

  context 'ServiceDescriptions' do
    let(:node) { xml.first(:xpath, service_description_path) }
    it 'is created' do
      expect(xml).to have_xpath(service_description_path)
    end

    context 'attributes lang' do
      it 'is rendered' do
        expect(node['xml:lang'])
          .to eq(attribute_consuming_service.service_descriptions.first.lang)
      end
    end

    it 'has expected value' do
      expect(node.text)
        .to eq(attribute_consuming_service.service_descriptions.first.value)
    end

    context 'multiple names' do
      let(:attribute_consuming_service) do
        create :attribute_consuming_service, :with_multiple_service_descriptions
      end
      it 'renders multiple' do
        expect(xml).to have_xpath(service_description_path, count: 3)
      end
    end
  end

  context 'RequestedAttributes' do
    context 'multiple attributes' do
      let(:attribute_consuming_service) do
        create :attribute_consuming_service, :with_multiple_requested_attributes
      end
      it 'renders multiple' do
        expect(xml).to have_xpath(requested_attribute_path, count: 3)
      end
    end
  end
end

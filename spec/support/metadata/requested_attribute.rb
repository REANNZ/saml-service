# frozen_string_literal: true

RSpec.shared_examples 'RequestedAttribute xml' do
  it 'is created' do
    expect(xml).to have_xpath(requested_attribute_path)
    expect(xml).to have_xpath(requested_attribute_path, count: 1)
    expect(node['Name']).to eq(requested_attribute.name)
    expect(node['NameFormat']).to be_falsey
  end

  let(:attribute_value_path) do
    "#{requested_attribute_path}/saml:AttributeValue"
  end

  let(:node) { xml.find(:xpath, requested_attribute_path) }

  context 'RequestedAttribute' do
    context 'attributes' do
      context 'NameFormat with value' do
        let(:requested_attribute) do
          create :requested_attribute, :with_name_format
        end
        it 'is included' do
          expect(node['NameFormat'])
            .to eq(requested_attribute.name_format.uri)
        end
      end

      context 'FriendlyName' do
        context 'without value' do
          let(:requested_attribute) { create :requested_attribute }
          it 'is not included' do
            expect(node['FriendlyName']).to be_falsey
          end
        end
        context 'with value' do
          let(:requested_attribute) do
            create :requested_attribute, friendly_name: Faker::Lorem.word
          end
          it 'is included' do
            expect(node['FriendlyName'])
              .to eq(requested_attribute.friendly_name)
          end
        end
      end

      context 'isRequired' do
        let(:requested_attribute) { create :requested_attribute, :is_required }
        it 'is rendered' do
          expect(node['isRequired']).to be_truthy
          expect(node['isRequired']).to eq(requested_attribute.required.to_s)
        end
      end
    end

    context 'AttributeValue' do
      let(:nodes) { xml.all(:xpath, attribute_value_path) }

      context 'Attribute has no attribute_values' do
        it 'is not created' do
          expect(xml).not_to have_xpath(attribute_value_path)
        end
      end
      context 'Attribute has attribute_values' do
        let(:requested_attribute) { create :requested_attribute, :with_values }
        it 'is created' do
          expect(xml).to have_xpath(attribute_value_path, count: 3)
          nodes.each_with_index do |node, i|
            expect(node.text)
              .to eq(requested_attribute.attribute_values[i].value)
          end
        end
      end
    end
  end
end

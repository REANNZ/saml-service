# frozen_string_literal: true

RSpec.shared_examples 'saml:Attribute xml' do
  let(:attribute_path) { '/saml:Attribute' }
  let(:attribute_value_path) { "#{attribute_path}/saml:AttributeValue" }

  let(:node) { xml.find(:xpath, attribute_path) }

  context 'Attribute' do
    it 'is created, sets name and uri' do
      expect(xml).to have_xpath(attribute_path, count: 1)
      expect(node['NameFormat']).to eq(attribute.name_format.uri)
      expect(node['Name']).to eq(attribute.name)
    end

    context 'attributes' do
      context 'NameFormat without value' do
        let(:attribute) { create :minimal_attribute }
        it 'is not included' do
          expect(node['NameFormat']).to be_falsey
        end
      end

      context 'FriendlyName without value' do
        let(:attribute) { create :minimal_attribute }
        it 'is not included' do
          expect(node['FriendlyName']).to be_falsey
        end
      end
      context 'with value' do
        let(:attribute) do
          create :minimal_attribute, friendly_name: Faker::Lorem.word
        end
        it 'is included' do
          expect(node['FriendlyName']).to eq(attribute.friendly_name)
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
        let(:attribute) { create :attribute, :with_values }
        it 'is created and renders expected values' do
          expect(xml).to have_xpath(attribute_value_path, count: 3)
          nodes.each_with_index do |node, i|
            expect(node.text).to eq(attribute.attribute_values[i].value)
          end
        end
      end
    end
  end
end

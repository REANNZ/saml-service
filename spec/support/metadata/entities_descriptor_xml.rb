# frozen_string_literal: true

RSpec.shared_examples 'md:EntitiesDescriptor xml' do
  let(:schema) { Nokogiri::XML::Schema.new(File.open('schema/top.xsd', 'r')) }
  let(:validation_errors) { schema.validate(Nokogiri::XML.parse(raw_xml)) }

  it 'is schema-valid and created, child EntityDescriptors, no RegistrationInfo node, no EntityAttributes node' do
    expect(validation_errors).to be_empty
    expect(xml).to have_xpath(entities_descriptor_path)
    expect(xml).to have_xpath(entity_descriptor_path, count: 5)
    expect(xml).to have_xpath(registration_info_path, count: 0)
    expect(xml).to have_xpath(entity_attributes_path, count: 0)
  end

  context 'Extensions' do
    context 'RegistrationInfo set' do
      let(:add_registration_info) { true }
      it 'creates RegistrationInfo node' do
        expect(xml).to have_xpath(registration_info_path, count: 1)
      end
    end

    context 'with EntityAttributes' do
      let(:add_entity_attributes) { true }
      it 'creates EntityAttributes node' do
        expect(xml).to have_xpath(entity_attributes_path, count: 1)
      end
    end
  end
end

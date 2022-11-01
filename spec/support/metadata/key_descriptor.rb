# frozen_string_literal: true

RSpec.shared_examples 'KeyDescriptor xml' do
  let(:key_descriptor_path) { '/KeyDescriptor' }
  let(:key_info_path) { "#{key_descriptor_path}/ds:KeyInfo" }
  let(:node) { xml.first(:xpath, key_descriptor_path) }

  it 'is created, no use' do
    expect(xml).to have_xpath(key_descriptor_path)
    expect(xml).to have_xpath(key_info_path)
    expect(node['use']).to be_falsey
  end

  context 'attributes use when populated' do
    context 'for signing' do
      let(:key_descriptor) do
        create(:key_descriptor, :signing)
      end
      it 'is rendered' do
        expect(node['use']).to eq('signing')
      end
    end
    context 'for encryption' do
      let(:key_descriptor) do
        create(:key_descriptor, :encryption)
      end
      it 'is rendered' do
        expect(node['use']).to eq('encryption')
      end
    end
  end
end

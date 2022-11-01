# frozen_string_literal: true

RSpec.shared_examples 'shibmd:KeyAuthority xml' do
  context 'CA keys without CA keys' do
    let(:key_authority_path) { "#{extensions_path}/shibmd:KeyAuthority" }
    let(:key_info_path) { "#{key_authority_path}/ds:KeyInfo" }

    it 'does not populate KeyAuthority node' do
      expect(xml).not_to have_xpath(key_authority_path)
    end

    context 'with CA keys KeyAuthority' do
      let(:add_ca_keys) { true }
      it 'is created' do
        expect(xml).to have_xpath(key_authority_path)
      end
      context 'attributes' do
        let(:node) { xml.find(:xpath, key_authority_path) }
        it 'sets VerifyDepth' do
          expect(node['VerifyDepth'])
            .to eq(metadata_instance.ca_verify_depth.to_s)
        end
      end
      context 'KeyInfo' do
        it 'creates two instances' do
          expect(xml).to have_xpath(key_info_path, count: 2)
        end
      end
    end
  end
end

# frozen_string_literal: true

RSpec.shared_examples 'mdrpi:RegistrationInfo xml' do
  context 'MDRPI Registation Info' do
    let(:registration_info_path) { '/mdrpi:RegistrationInfo' }
    let(:registration_policies_path) do
      "#{registration_info_path}/mdrpi:RegistrationPolicy"
    end

    it 'is created' do
      expect(xml).to have_xpath(registration_info_path, count: 1)
    end

    context 'attributes, registration instant, registrationAuthority' do
      let(:node) { xml.find(:xpath, registration_info_path) }
      it 'sets registration authority' do
        expect(node['registrationAuthority'])
          .to eq(root_node.registration_info.registration_authority)
        expect(node['registrationInstant'])
          .to eq(root_node.registration_info
                   .registration_instant_utc.xmlschema)
      end
    end

    context 'Registration Policies' do
      let(:node) { xml.find(:xpath, registration_policies_path) }
      let(:rp) do
        root_node.registration_info.registration_policies.first
      end
      it 'is created with lang and text' do
        expect(xml).to have_xpath(registration_policies_path, count: 1)
        expect(node['xml:lang']).to eq(rp.lang)
        expect(node.text).to eq(rp.uri)
      end
    end
  end
end

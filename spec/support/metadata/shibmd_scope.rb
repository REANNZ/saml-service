# frozen_string_literal: true

RSpec.shared_examples 'shibmd:Scope xml' do
  let(:shibmd_scope_path) { '/shibmd:Scope' }
  let(:node) { xml.first(:xpath, shibmd_scope_path) }
  let(:regexp) { false }
  let(:scope) { create :shibmd_scope, regexp: regexp }

  before { subject.shibmd_scope(scope) }

  context 'shibmd:Scope' do
    it 'sets node value' do
      expect(node.text).to eq(scope.value)
      expect(node[:regexp]).to eq('false')
    end

    context 'regexp with' do
      let(:regexp) { true }
      it 'is true' do
        expect(node[:regexp]).to eq('true')
      end
    end
  end
end

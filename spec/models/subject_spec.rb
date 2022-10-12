# frozen_string_literal: true

require 'rails_helper'

require 'gumboot/shared_examples/subjects'

RSpec.describe Subject, type: :model do
  it_behaves_like 'a basic model'

  include_examples 'Subjects'

  let(:subject_obj) { create(:subject, :authorized) }

  context '#functioning?' do
    subject(:functioning) { subject_obj.functioning? }
    before { subject_obj.enabled = enabled }
    context 'when enabled' do
      let(:enabled) { true }

      it 'is true' do
        expect(functioning).to be_truthy
      end
    end

    context 'when not enabled' do
      let(:enabled) { false }

      it 'is false' do
        expect(functioning).to_not be_truthy
      end
    end
  end

  context '#permissions' do
    subject(:permissions) { subject_obj.permissions }
    it 'returns permissions' do
      expect(permissions).to eq(['*'])
    end
  end
end

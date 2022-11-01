# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MDRPI::RegistrationInfo, type: :model do
  it_behaves_like 'a basic model'

  it { is_expected.to have_many_to_one :metadata_instance }
  it { is_expected.to have_many_to_one :entity_descriptor }
  it { is_expected.to validate_presence :registration_authority }
  it { is_expected.to respond_to :registration_instant }

  context 'instance validations' do
    let(:subject) { create :mdrpi_registration_info }

    it { is_expected.to validate_presence :registration_policies }

    context 'ownership' do
      it 'must be owned' do
        expect(subject).not_to be_valid
      end

      it 'owned by metadata_instance' do
        subject.metadata_instance = create :metadata_instance
        expect(subject).to be_valid
      end

      it 'owned by entity_descriptor' do
        subject.entity_descriptor = create :entity_descriptor
        expect(subject).to be_valid
      end

      it 'cant have multiple owners' do
        subject.metadata_instance = create :metadata_instance
        subject.entity_descriptor = create :entity_descriptor

        expect(subject).not_to be_valid
      end
    end
  end

  context '#registration_instant_utc' do
    let(:subject) { create :mdrpi_registration_info }

    around { |example| Timecop.freeze { example.run } }

    it 'uses created_at if registration_instant not explicitly set' do
      expect(subject.registration_instant_utc).to eq(subject.created_at.utc)
    end
    it 'uses registration_instant if set' do
      subject.registration_instant = 2.months.ago
      expect(subject.registration_instant_utc)
        .to eq(subject.registration_instant.utc)
    end
  end

  describe '#destroy' do
    subject do
      create :mdrpi_registration_info
    end

    it 'is successfully destroyed' do
      expect { subject.destroy }.not_to raise_error
    end
  end
end

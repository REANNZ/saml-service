require 'rails_helper'

RSpec.describe MDRPI::PublicationInfo, type: :model do
  it_behaves_like 'a basic model'

  it { is_expected.to have_many_to_one :entities_descriptor }
  it { is_expected.to have_many_to_one :entity_descriptor }

  it { is_expected.to validate_presence :publisher }

  context 'optional attributes' do
    it { is_expected.to have_one_to_many :usage_policies }
  end

  let(:subject) { create :mdrpi_publication_info }
  context 'ownership' do
    it 'must be owned' do
      expect(subject).not_to be_valid
    end

    it 'owned by entities_descriptor' do
      subject.entities_descriptor = create :entities_descriptor
      expect(subject).to be_valid
    end

    it 'owned by entity_descriptor' do
      subject.entity_descriptor = create :entity_descriptor
      expect(subject).to be_valid
    end

    it 'cant have multiple owners' do
      subject.entities_descriptor = create :entities_descriptor
      subject.entity_descriptor = create :entity_descriptor

      expect(subject).not_to be_valid
    end
  end

end
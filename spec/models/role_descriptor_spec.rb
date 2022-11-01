# frozen_string_literal: true

require 'rails_helper'

describe RoleDescriptor do
  it_behaves_like 'a basic model'

  context 'deprecated structure' do
    it { is_expected.not_to have_column :active }
  end

  context 'validations' do
    it { is_expected.to validate_presence :entity_descriptor }
    it { is_expected.to have_many_to_one :entity_descriptor }
    it { is_expected.to validate_presence :enabled }

    context 'instance validations' do
      subject { create :role_descriptor }
      it { is_expected.to validate_presence :protocol_supports }
    end
  end

  context 'optional attributes' do
    it { is_expected.to have_many_to_one :organization }
    it { is_expected.to have_one_to_many :key_descriptors }
    it { is_expected.to have_one_to_many :contact_people }
    it { is_expected.to have_one_to_many :scopes }
    it { is_expected.to have_column :extensions, type: :text }

    it { is_expected.to have_one_to_one :ui_info }
  end

  it 'doesnt have extentions, key_descriptors, contact people and scopes' do
    expect(subject.extensions?).to be_falsey
    expect(subject.key_descriptors?).to be_falsey
    expect(subject.contact_people?).to be_falsey
    expect(subject.scopes?).to be_falsey
  end

  describe '#extensions?' do
    context 'with extensions' do
      subject { create :role_descriptor, :with_extensions }
      it 'is true' do
        expect(subject.extensions?).to be_truthy
      end
    end
    context 'with ui_info' do
      subject { create :role_descriptor, :with_ui_info }
      it 'is true' do
        expect(subject.extensions?).to be_truthy
      end
    end
    context 'with scope' do
      subject { create :role_descriptor, :with_scope }
      it 'is true' do
        expect(subject.extensions?).to be_truthy
      end
    end
    context 'with scope, ui_info and extensions' do
      subject do
        create :role_descriptor, :with_ui_info, :with_extensions, :with_scope
      end
      it 'is true' do
        expect(subject.extensions?).to be_truthy
      end
    end
  end

  describe '#key_descriptors?' do
    context 'with key descriptors' do
      subject { create :role_descriptor, :with_key_descriptors }
      it 'is true' do
        expect(subject.key_descriptors?).to be_truthy
      end
    end
  end

  describe '#contact_people?' do
    context 'with contacts' do
      subject { create :role_descriptor, :with_contacts }
      it 'is true' do
        expect(subject.contact_people?).to be_truthy
      end
    end
  end

  describe '#scopes?' do
    context 'with scope' do
      subject { create :role_descriptor, :with_scope }
      it 'is true' do
        expect(subject.scopes?).to be_truthy
      end
    end
  end

  describe '#functioning?' do
    context 'when RoleDescriptor is valid' do
      subject { create :role_descriptor }

      before { subject.enabled = true }

      it 'valid' do
        expect(subject).to be_valid
        expect(subject).to be_functioning
        subject.enabled = false
        expect(subject).not_to be_functioning
      end
    end

    context 'when RoleDescriptor is invalid' do
      subject { create :role_descriptor }

      before do
        subject.enabled = true
        subject.entity_descriptor = nil
      end

      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject).not_to be_functioning
        subject.enabled = false
        expect(subject).not_to be_functioning
      end
    end
  end

  describe '#edugain_compliant?' do
    context 'with ui_info' do
      subject { create :role_descriptor, :with_ui_info }

      it { is_expected.to be_edugain_compliant }

      context 'without display_names' do
        before do
          subject.ui_info.display_names.each(&:destroy)
          subject.reload
        end

        it { is_expected.not_to be_edugain_compliant }
      end

      context 'without descriptions' do
        before do
          subject.ui_info.descriptions.each(&:destroy)
          subject.reload
        end

        it { is_expected.not_to be_edugain_compliant }
      end
    end

    context 'without ui_info' do
      subject { create :role_descriptor }
      it { is_expected.not_to be_edugain_compliant }
    end
  end

  describe '#destroy' do
    subject do
      create :role_descriptor, :with_error_url, :with_key_descriptors,
             :with_extensions, :with_organization,
             :with_contacts, :with_scopes, :with_ui_info
    end

    it 'is successfully destroyed' do
      expect { subject.destroy }.not_to raise_error
    end
  end
end

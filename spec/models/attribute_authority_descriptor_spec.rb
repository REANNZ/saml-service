# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AttributeAuthorityDescriptor, type: :model do
  context 'Extends RoleDescriptor' do
    it { is_expected.to have_one_to_many :attribute_services }
    it { is_expected.to have_one_to_many :assertion_id_request_services }
    it { is_expected.to have_one_to_many :name_id_formats }
    it { is_expected.to have_one_to_many :attribute_profiles }
    it { is_expected.to have_one_to_many :attributes }
    it { is_expected.to validate_presence :attribute_services }

    describe '#assertion_id_request_services?' do
      context 'when populated' do
        subject do
          create(:attribute_authority_descriptor,
                 :with_multiple_assertion_id_request_services)
        end
        it 'is true' do
          expect(subject.assertion_id_request_services?).to be_truthy
        end
      end
      context 'when unpopulated' do
        subject { create :attribute_authority_descriptor }
        it 'is false' do
          expect(subject.assertion_id_request_services?).to be_falsey
        end
      end
    end

    describe '#name_id_formats?' do
      context 'when populated' do
        subject do
          create(:attribute_authority_descriptor,
                 :with_multiple_name_id_formats)
        end
        it 'is true' do
          expect(subject.name_id_formats?).to be_truthy
        end
      end
      context 'when unpopulated' do
        subject { create :attribute_authority_descriptor }
        it 'is false' do
          expect(subject.name_id_formats?).to be_falsey
        end
      end
    end

    describe '#attribute_profiles?' do
      context 'when populated' do
        subject do
          create(:attribute_authority_descriptor,
                 :with_multiple_attribute_profiles)
        end
        it 'is true' do
          expect(subject.attribute_profiles?).to be_truthy
        end
      end
      context 'when unpopulated' do
        subject { create :attribute_authority_descriptor }
        it 'is false' do
          expect(subject.attribute_profiles?).to be_falsey
        end
      end
    end

    describe '#attributes?' do
      context 'when populated' do
        subject do
          create(:attribute_authority_descriptor,
                 :with_multiple_attributes)
        end
        it 'is true' do
          expect(subject.attributes?).to be_truthy
        end
      end
      context 'when unpopulated' do
        subject { create :attribute_authority_descriptor }
        it 'is false' do
          expect(subject.attributes?).to be_falsey
        end
      end
    end
  end

  describe '#destroy' do
    subject do
      create :attribute_authority_descriptor, :with_multiple_attribute_services,
             :with_multiple_assertion_id_request_services,
             :with_multiple_name_id_formats,
             :with_multiple_attribute_profiles,
             :with_multiple_attributes
    end

    it 'is successfully destroyed' do
      expect { subject.destroy }.not_to raise_error
    end
  end
end

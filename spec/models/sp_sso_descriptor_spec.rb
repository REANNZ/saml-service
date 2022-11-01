# frozen_string_literal: true

require 'rails_helper'

describe SPSSODescriptor do
  context 'extends sso_descriptor' do
    it { is_expected.to validate_presence :entity_descriptor }
    it { is_expected.to have_many_to_one :entity_descriptor }

    it { is_expected.to validate_presence :authn_requests_signed }
    it { is_expected.to validate_presence :want_assertions_signed }
    it { is_expected.to have_one_to_many :attribute_consuming_services }

    let(:subject) { create :sp_sso_descriptor }
    it 'works' do
      expect(subject).to validate_presence :assertion_consumer_services
      expect(subject).to have_one_to_many :attribute_consuming_services
      expect(subject.extensions?).to be_falsey
      subject.assertion_consumer_services.clear
      expect(subject).not_to be_valid
    end

    describe '#attribute_consuming_services?' do
      context 'when populated' do
        subject do
          create(:sp_sso_descriptor, :with_attribute_consuming_services)
        end
        it 'is true' do
          expect(subject.attribute_consuming_services?).to be_truthy
        end
      end
      context 'when unpopulated' do
        subject { create :sp_sso_descriptor }
        it 'is false' do
          expect(subject.attribute_consuming_services?).to be_falsey
        end
      end
    end

    describe '#extensions?' do
      context 'with extensions' do
        subject { create :sp_sso_descriptor, :with_extensions }
        it 'is true' do
          expect(subject.extensions?).to be_truthy
        end
      end
      context 'with ui_info' do
        subject { create :sp_sso_descriptor, :with_ui_info }
        it 'is true' do
          expect(subject.extensions?).to be_truthy
        end
      end
      context 'with discovery_response_services' do
        subject { create :sp_sso_descriptor, :with_discovery_response_services }
        it 'is true' do
          expect(subject.extensions?).to be_truthy
        end
      end
      context 'with extensions, ui_info and discovery_response_services' do
        subject do
          create :sp_sso_descriptor,
                 :with_ui_info, :with_discovery_response_services,
                 :with_extensions
        end
        it 'is true' do
          expect(subject.extensions?).to be_truthy
        end
      end
    end
  end

  describe '#destroy' do
    subject do
      create :sp_sso_descriptor, :with_authn_requests_signed,
             :with_want_assertions_signed,
             :request_attributes,
             :with_attribute_consuming_services,
             :with_ui_info, :with_discovery_response_services
    end

    it 'is successfully destroyed' do
      expect { subject.destroy }.not_to raise_error
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Endpoint, type: :model do
  it_behaves_like 'a basic model'

  context 'validations' do
    it { is_expected.to validate_presence :binding }
    it { is_expected.to validate_presence :location }

    context 'instance validations' do
      subject { create :_endpoint }
      context 'location' do
        it 'rejects invalid URL' do
          subject.location = 'invalid'
          expect(subject).not_to be_valid
        end

        it 'is valid with http, https and/or port' do
          subject.location = 'http://example.org'
          expect(subject).to be_valid
          subject.location = 'https://example.org'
          expect(subject).to be_valid
          subject.location = 'https://example.org:8080'
          expect(subject).to be_valid
        end
      end

      context 'response_location' do
        subject { create(:_endpoint) }

        it 'rejects invalid URL' do
          subject.response_location = 'invalid'
          expect(subject).not_to be_valid
        end

        it 'is valid with http, https and/or port' do
          subject.response_location = 'http://example.org'
          expect(subject).to be_valid
          subject.response_location = 'https://example.org'
          expect(subject).to be_valid
          subject.response_location = 'https://example.org:8080'
          expect(subject).to be_valid
        end
      end
    end
  end

  describe '#response_location?' do
    context 'when populated' do
      subject { create(:_endpoint, :response_location) }
      it 'is true' do
        expect(subject.response_location?).to be_truthy
      end
    end
    context 'when unpopulated' do
      subject { create :_endpoint }
      it 'is false' do
        expect(subject.response_location?).to be_falsey
      end
    end
  end
end

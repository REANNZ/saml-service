# frozen_string_literal: true

require 'rails_helper'

describe LocalizedURI do
  it_behaves_like 'a basic model'

  it { is_expected.to validate_presence :uri }
  it { is_expected.to validate_presence :lang }

  describe '#uri' do
    it 'rejects invalid URL' do
      subject.lang = 'en'
      subject.uri = 'invalid'
      expect(subject).not_to be_valid
    end

    context 'valid URL formats' do
      it 'supports http, https and port' do
        subject.lang = 'en'
        subject.uri = 'http://example.org'
        expect(subject).to be_valid
        subject.lang = 'en'
        subject.uri = 'https://example.org'
        expect(subject).to be_valid
        subject.lang = 'en'
        subject.uri = 'hTtP://example.org'
        expect(subject).to be_valid
        subject.lang = 'en'
        subject.uri = 'HttpS://example.org'
        expect(subject).to be_valid
        subject.lang = 'en'
        subject.uri = 'https://example.org:8080'
        expect(subject).to be_valid
      end
    end
  end
end

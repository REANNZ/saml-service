# frozen_string_literal: true

require 'rails_helper'

describe SamlURI do
  it_behaves_like 'a basic model'

  it { is_expected.to validate_presence :uri }

  context 'validations' do
    context 'uri' do
      let(:saml_uri) { build(:saml_uri, uri: uri) }
      before { saml_uri.valid? }
      subject { saml_uri }

      context 'as url' do
        let(:uri) { Faker::Internet.url }
        it { is_expected.to be_valid }
      end

      context 'as uri (but not url)' do
        context 'with a method' do
          let(:method) { Faker::Lorem.word }
          let(:parts) { Faker::Lorem.characters(number: 5) }
          let(:uri) { "#{method}:#{parts}" }
          it { is_expected.to be_valid }

          context 'and parts with numbers, letters, hyphens and periods' do
            def part
              [Faker::Lorem.characters(number: 5), '.', '-'].sample
            end
            let(:sections) { (1..10).to_a.sample }
            let(:parts) { Array.new(sections) { part }.join(':') }
            it { is_expected.to be_valid }
          end
        end
      end

      context 'as a single word' do
        let(:uri) { 'BXGOTY3T' }
        it { is_expected.to be_valid }
      end
    end
  end
end

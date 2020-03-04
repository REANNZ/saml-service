# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MDUI::GeolocationHint, type: :model do
  it_behaves_like 'a basic model'

  it { is_expected.to have_many_to_one :disco_hints }
  it { is_expected.to validate_presence :disco_hints }
  it { is_expected.to validate_presence :uri }

  context 'destructuring the geo uri' do
    let(:latitude) { Faker::Address.latitude.to_s }
    let(:longitude) { Faker::Address.longitude.to_s }
    let(:altitude) { Faker::Number.number(digits: 3).to_s }

    subject do
      parts = [latitude, longitude, altitude].compact
      build(:mdui_geolocation_hint, uri: "geo:#{parts.join(',')}")
    end

    describe '#latitude' do
      it 'returns the latitude portion of the uri' do
        expect(subject.latitude).to eq(latitude)
      end
    end

    describe '#longitude' do
      it 'returns the longitude portion of the uri' do
        expect(subject.longitude).to eq(longitude)
      end
    end

    describe '#altitude' do
      it 'returns the altitude portion of the uri' do
        expect(subject.altitude).to eq(altitude)
      end

      context 'for a 2-part geo URI' do
        let(:altitude) { nil }

        it 'returns nil for altitude' do
          expect(subject.altitude).to be_nil
        end
      end
    end
  end

  describe '#valid_uri?' do
    let(:lat) { Faker::Number.decimal(l_digits: 5) }
    let(:long) { Faker::Number.decimal(l_digits: 5) }
    let(:alt) { Faker::Number.decimal(l_digits: 2) }

    context 'valid uri values' do
      it 'minimal uri' do
        uri = "geo:#{lat},#{long}"
        expect(MDUI::GeolocationHint.valid_uri?(uri)).to be_truthy
      end

      it 'extended uri' do
        uri = "geo:#{lat},#{long},#{alt}"
        expect(MDUI::GeolocationHint.valid_uri?(uri)).to be_truthy
      end

      it 'with parameters' do
        uri = "geo:#{lat},#{long},#{alt};u=35"
        expect(MDUI::GeolocationHint.valid_uri?(uri)).to be_truthy
      end
    end

    context 'invalid uri' do
      it 'not a URI' do
        uri = "xyz:#{lat}, #{long}" # space is invalid
        expect(MDUI::GeolocationHint.valid_uri?(uri)).to be_falsey
      end

      it 'no geo scheme' do
        uri = "xyz:#{lat},#{long}"
        expect(MDUI::GeolocationHint.valid_uri?(uri)).to be_falsey
      end

      it 'no opaque component' do
        uri = 'geo:'
        expect(MDUI::GeolocationHint.valid_uri?(uri)).to be_falsey
      end

      it 'values are not comma seperated' do
        uri = "geo:#{lat}:#{long}"
        expect(MDUI::GeolocationHint.valid_uri?(uri)).to be_falsey
      end
    end
  end

  describe '#parse_uri_into_parts' do
    let(:lat) { Faker::Number.decimal(l_digits: 5).to_s }
    let(:long) { Faker::Number.decimal(l_digits: 5).to_s }
    let(:alt) { Faker::Number.decimal(l_digits: 2).to_s }
    let(:parsed_uri) { MDUI::GeolocationHint.parse_uri_into_parts(uri) }

    shared_examples 'provides minimal values correctly' do
      it 'provides expected values' do
        expect(parsed_uri[0]).to eq(lat)
        expect(parsed_uri[1]).to eq(long)
        expect(parsed_uri[2]).to be_nil
      end
    end

    shared_examples 'provides extended values correctly' do
      it 'provides expected values including altitude' do
        expect(parsed_uri[0]).to eq(lat)
        expect(parsed_uri[1]).to eq(long)
        expect(parsed_uri[2]).to eq(alt)
      end
    end

    context 'with lat and long' do
      let(:uri) { "geo:#{lat},#{long}" }
      include_examples 'provides minimal values correctly'

      context 'with additional parameters' do
        let(:uri) { "geo:#{lat},#{long};u=#{Faker::Number.number(digits: 2)}" }
        include_examples 'provides minimal values correctly'
      end
    end

    context 'with lat, long and alt' do
      let(:uri) { "geo:#{lat},#{long},#{alt}" }
      include_examples 'provides extended values correctly'

      context 'with additional parameters' do
        let(:uri) do
          "geo:#{lat},#{long},#{alt};u=#{Faker::Number.number(digits: 2)}"
        end
        include_examples 'provides extended values correctly'
      end
    end
  end
end

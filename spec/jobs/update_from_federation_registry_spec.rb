# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateFromFederationRegistry do
  around { |e| Timecop.freeze { e.run } }

  RSpec::Matchers.define(:have_fr_id) do |expected|
    match do |actual|
      fr_id = FederationRegistryObject
              .where(internal_class_name: actual.class.name,
                     internal_id: actual.id)
              .first.try(:fr_id)

      fr_id == expected
    end

    description { "have Federation Registry ID: #{expected}" }
  end

  def record_fr_id(object, fr_id)
    FederationRegistryObject.create(internal_class_name: object.class.name,
                                    internal_id: object.id,
                                    fr_id: fr_id)
  end

  let(:fr_source) { create(:federation_registry_source) }
  let(:federation_tag) { Faker::Lorem.word }
  let(:authorization) do
    %(AAF-FR-EXPORT service="saml-service", key="#{fr_source.secret}")
  end
  let(:request_headers) { { 'Authorization' => authorization } }
  let(:truncated_now) { Time.zone.at(Time.now.to_i) }

  delegate :entity_source, to: :fr_source
  delegate :known_entities, to: :entity_source

  def stub_fr_request(kind)
    url = "https://#{fr_source.hostname}/federationregistry/export/" \
          "#{kind.to_s.sub('_', '')}"

    stub_request(:get, url).with(headers: request_headers)
                           .to_return(status: 200,
                                      body: JSON.generate(kind => send(kind)))
  end

  def self.verify_attributes(attr_generators)
    attr_generators.each do |attr, value|
      v = value.is_a?(Proc) ? value : -> { value }

      it "has an updated `#{attr}` attribute" do
        expect(subject).to have_attributes(attr => instance_exec(&v))
      end
    end
  end

  def self.verify_checked_all_attributes(attrs)
    it 'has all attributes validated' do
      expect((attrs - [:id]).uniq).to contain_exactly(*attrs.uniq)
    end
  end

  def self.verify(attr_generators)
    verify_attributes(attr_generators)
    verify_checked_all_attributes(attr_generators.keys)

    it 'is valid' do
      expect(subject).to be_valid
    end
  end

  def fr_time(time)
    time.utc.strftime('%Y-%m-%dT%H:%M:%S+0000')
  end

  it_behaves_like 'ETL::Organizations'
  it_behaves_like 'ETL::Contacts'
  it_behaves_like 'ETL::EntityDescriptors'
  it_behaves_like 'ETL::IdentityProviders'
  it_behaves_like 'ETL::AttributeAuthorities'
  it_behaves_like 'ETL::ServiceProviders'

  describe '#perform' do
    subject(:perform) { described_class.perform(id: fr_source.id) }

    before do
      stub_request(:get, "https://#{fr_source.hostname}/federationregistry/export/contacts")
        .with(headers: request_headers)
        .to_return(status: 200,
                   body: JSON.generate({ contacts: [] }))

      stub_request(:get, "https://#{fr_source.hostname}/federationregistry/export/organizations")
        .with(headers: request_headers)
        .to_return(status: 200,
                   body: JSON.generate({ organizations: [] }))
    end

    it 'works' do
      expect(perform).to eq(true)
    end

    context 'when data isnt available' do
      before do
        mock_response = double(Net::HTTPUnauthorized)
        allow(mock_response).to receive(:code)
        allow(mock_response).to receive(:message)
        mock = double(Net::HTTP)
        allow(mock).to receive(:use_ssl=)
        allow(mock).to receive(:read_timeout=)
        allow(mock).to receive(:request).and_return(mock_response)
        allow(Net::HTTP).to receive(:new).and_return(mock)
      end
      it 'raises' do
        expect { perform }.to raise_error(StandardError, /Unable to update FederationRegistrySource/)
      end
    end
  end
end

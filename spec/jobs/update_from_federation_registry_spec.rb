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
end

# frozen_string_literal: true

RSpec.shared_examples 'ETL::AttributeAuthorities' do
  include_examples 'ETL::Common'
  # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
  def create_idp_json(idp)
    contact_people =
      contact_instances.map { |cp| contact_person_json(cp) } +
      sirtfi_contact_instances.map { |cp| sirtfi_contact_person_json(cp) }
    {
      id: idp.id,
      display_name: Faker::Lorem.sentence,
      description: Faker::Lorem.sentence,
      attribute_authority_only: false,
      functioning: idp.functioning?,
      created_at: idp_created_at,
      saml: {
        scope: scope,
        authnrequests_signed: idp.want_authn_requests_signed,
        single_sign_on_services:
          idp.single_sign_on_services.map { |s| endpoint_json(s) },
        name_id_mapping_services:
          idp.name_id_mapping_services.map { |s| endpoint_json(s) },
        assertion_id_request_services:
          idp.assertion_id_request_services.map { |s| endpoint_json(s) },
        attribute_profiles:
          idp.attribute_profiles.map { |ap| saml_uri_json(ap) },
        attributes: attribute_instances.map { |a| attribute_json(a) },
        sso_descriptor: {
          role_descriptor: {
            protocol_support_enumerations:
              idp.protocol_supports.map { |pse| saml_uri_json(pse) },
            key_descriptors:
              idp.key_descriptors.map { |kd| key_descriptor_json(kd) }
                 .push(bad_key_descriptor_json),
            contact_people: contact_people,
            error_url: idp.error_url
          },
          name_id_formats:
            idp.name_id_formats.map { |nidf| saml_uri_json(nidf) },
          artifact_resolution_services:
            idp.artifact_resolution_services.map do |ars|
              indexed_endpoint_json(ars)
            end,
          single_logout_services:
            idp.single_logout_services.map { |slo| endpoint_json(slo) },
          manage_nameid_services:
            idp.manage_name_id_services.map { |mnids| endpoint_json(mnids) }
        }
      }
    }
  end
  # rubocop:enable Metrics/MethodLength,Metrics/AbcSize

  # rubocop:disable Metrics/MethodLength
  def create_aa_json(idp, aa, extract)
    {
      id: aa.id,
      display_name: Faker::Lorem.sentence,
      description: Faker::Lorem.sentence,
      functioning: aa.functioning?,
      created_at: idp_created_at,
      saml: {
        extract_metadata_from_idp_sso_descriptor: extract,
        attribute_services:
          aa.attribute_services.map { |as| endpoint_json(as) },
        idp_sso_descriptor: idp.id
      }
    }
  end
  # rubocop:enable Metrics/MethodLength

  def attribute_json(a)
    {
      id: a[:id],
      name: Faker::Lorem.word
    }
  end

  def attribute_base_json(a)
    {
      id: a[:id],
      description: a[:description],
      oid: a[:oid],
      name_format: {
        uri: 'urn:oasis:names:tc:SAML:2.0:attrname-format:uri'
      }
    }
  end

  def fr_object(name, id)
    FederationRegistryObject.create(internal_class_name: name,
                                    internal_id: id, fr_id: id)
  end

  def run
    described_class.new(id: fr_source.id)
                   .attribute_authorities(entity_descriptor, ed_data)
  end

  let(:identity_provider_instances) do
    create_list(:idp_sso_descriptor, idp_count,
                :with_requests_signed,
                :with_multiple_single_sign_on_services,
                :with_assertion_id_request_services,
                :with_name_id_mapping_services,
                :with_attribute_profiles,
                :with_attributes,
                :with_name_id_formats,
                :with_single_logout_services,
                :with_manage_name_id_services,
                :with_key_descriptors,
                :with_artifact_resolution_services,
                :with_disco_hints)
  end

  let(:identity_providers_list) do
    identity_provider_instances.map { |idp| create_idp_json(idp) }
  end

  let(:identity_providers) do
    identity_providers_list
  end

  let(:attribute_authorities_instances) do
    create_list(:attribute_authority_descriptor, aa_count)
  end

  let(:attribute_authorities_list) do
    attribute_authorities_instances.map do |aa|
      create_aa_json(identity_provider_instances.first, aa, true)
    end
  end

  let(:attribute_authorities) { attribute_authorities_list }

  let(:idp_created_at) { Time.zone.at(rand(Time.now.utc.to_i)) }

  let(:attribute_instances) do
    (0..attribute_count).map do |i|
      {
        id: i,
        description: Faker::Lorem.sentence,
        oid: "#{Faker::Number.number(digits: 4)}:" \
             "#{Faker::Number.number(digits: 4)}"
      }
    end
  end

  let(:attributes_list) do
    attribute_instances.map { |a| attribute_base_json(a) }
  end

  let(:attributes) { attributes_list }

  let(:entity_descriptor) { create :entity_descriptor }

  let(:ed_data) do
    {
      saml: {
        identity_providers:
          identity_provider_instances.map do |idp|
            { id: idp.id, functioning: idp.functioning? }
          end,
        attribute_authorities:
          attribute_authorities_instances.map do |aa|
            { id: aa.id, functioning: aa.functioning? }
          end
      }
    }
  end

  before do
    stub_fr_request(:contacts)

    [*contact_instances, *sirtfi_contact_instances]
      .each { |c| fr_object(Contact.name, c.id) }

    stub_fr_request(:attributes)
    stub_fr_request(:identity_providers)
    stub_fr_request(:attribute_authorities)
  end

  context 'creating an AttributeAuthorityDescriptor' do
    let(:source_idp) { identity_provider_instances.first }
    let(:source_aa) { attribute_authorities_instances.first }

    let(:idp_count) { 1 }
    let(:aa_count) { 1 }
    let(:contact_count) { 1 }
    let(:sirtfi_contact_count) { 1 }
    let(:attribute_count) { 3 }

    subject { AttributeAuthorityDescriptor.last }

    it 'creates a new instance and tag' do
      expect { run }
        .to change { AttributeAuthorityDescriptor.count }.by(aa_count).and(
          change { Tag.count }.by(1)
        )
      expect(AttributeAuthorityDescriptor.last).to be_valid
    end

    context 'when no key type' do
      let(:identity_providers) do
        identity_providers_list.each do |json|
          json[:saml][:sso_descriptor][:role_descriptor][:key_descriptors].each do |descriptor|
            descriptor.delete(:type)
          end
        end
      end

      it 'creates a new instance' do
        expect { run }
          .to change { AttributeAuthorityDescriptor.count }.by(aa_count)
      end
    end

    context 'when no key info' do
      let(:identity_providers) do
        identity_providers_list.each do |json|
          json[:saml][:sso_descriptor][:role_descriptor][:key_descriptors].each do |descriptor|
            descriptor.delete(:key_info)
          end
        end
      end

      it 'raises validation error' do
        expect { run }
          .to raise_error(Sequel::ValidationFailed, 'key_info is not present')
      end
    end

    context 'when no key info certificate' do
      let(:identity_providers) do
        identity_providers_list.each do |json|
          json[:saml][:sso_descriptor][:role_descriptor][:key_descriptors].each do |descriptor|
            descriptor[:key_info].delete(:certificate)
          end
        end
      end

      it 'raises validation error' do
        expect { run }
          .to raise_error(Sequel::ValidationFailed, 'key_info is not present')
      end
    end

    context 'when no key info certificate data' do
      let(:identity_providers) do
        identity_providers_list.each do |json|
          json[:saml][:sso_descriptor][:role_descriptor][:key_descriptors].each do |descriptor|
            descriptor[:key_info][:certificate].delete(:data)
          end
        end
      end

      it 'raises validation error' do
        expect { run }
          .to raise_error(Sequel::ValidationFailed, 'key_info is not present')
      end
    end

    context 'when not functioning' do
      let(:attribute_authorities_list) do
        attribute_authorities_instances.map do |aa|
          json = create_aa_json(identity_provider_instances.first, aa, true)
          json[:saml][:attribute_services].each { |service| service[:functioning] = false }
          json
        end
      end

      it 'creates a new instance' do
        expect { run }.not_to change(AttributeService, :count)
      end
    end

    context 'without a scope' do
      let(:attribute_authorities_list) do
        attribute_authorities_instances.map do |aa|
          create_aa_json(identity_provider_instances.first, aa, false)
        end
      end

      it 'works' do
        expect { run }.to raise_error(StandardError, 'Does not support AA (even standalone) who do not derive from IdP')
      end
    end

    context 'created instance' do
      before { run }

      context 'correct attributes' do
        verify(created_at: -> { idp_created_at },
               updated_at: -> { truncated_now },
               error_url: -> { source_idp.error_url })
      end

      context 'with idp_sso_descriptors' do
        let(:entity_descriptor) { create :entity_descriptor, :with_idp }

        it 'works' do
          expect(subject.scopes.size).to eq(1)
        end
      end

      context 'scopes' do
        it 'sets scope and sets regex to false' do
          expect(subject.scopes.size).to eq(1)
          expect(subject.scopes.first.value).to eq(scope)
          expect(subject.scopes.first.regexp).not_to be
        end

        context 'regex scope' do
          let(:scope) { '^([a-zA-Z0-9-]{1,63}[.]){0,2}example.edu$' }

          it 'sets regex to true' do
            expect(subject.scopes.first.regexp).to be
          end
        end
      end

      context 'assertion_id_request_services' do
        include_examples 'endpoint' do
          let(:target) { subject.assertion_id_request_services }
          let(:source) { source_idp.assertion_id_request_services }
        end
      end

      context 'attribute_profiles' do
        include_examples 'saml_uris' do
          let(:target) { subject.attribute_profiles }
          let(:source) { source_idp.attribute_profiles }
        end
      end

      context 'attribute_instances' do
        include_examples 'saml_attributes' do
          let(:target) { subject.attributes }
          let(:source) { attribute_instances }
        end
      end

      context 'protocol supports' do
        include_examples 'saml_uris' do
          let(:target) { subject.protocol_supports }
          let(:source) { source_idp.protocol_supports }
        end
      end

      context 'key descriptors' do
        include_examples 'key_descriptors' do
          let(:target) { subject.key_descriptors }
          let(:source) { source_idp.key_descriptors }
        end
      end

      context 'contact people' do
        include_examples 'contact_people' do
          let(:target) { subject.entity_descriptor.contact_people }
          let(:source) do
            identity_providers
              .first[:saml][:sso_descriptor][:role_descriptor][:contact_people]
              .reject { |cp| cp[:type][:name] == 'Security' }
          end
        end
      end

      context 'nameid formats' do
        include_examples 'saml_uris' do
          let(:target) { subject.name_id_formats }
          let(:source) { source_idp.name_id_formats }
        end
      end

      context 'attribute_services' do
        include_examples 'endpoint' do
          let(:target) { subject.attribute_services }
          let(:source) { source_aa.attribute_services }
        end
      end
    end
  end

  context 'updating an AttributeAuthorityDescriptor' do
    let(:source_idp) { identity_provider_instances.first }
    let(:source_aa) { attribute_authorities_instances.first }
    let(:idp_count) { 1 }
    let(:aa_count) { 1 }
    let(:contact_count) { 1 }
    let(:sirtfi_contact_count) { 1 }
    let(:attribute_count) { 3 }

    subject { AttributeAuthorityDescriptor.last }

    before { run }

    include_examples 'updating a RoleDescriptor'

    it 'uses the existing instance, doesnt create tags, updates' do
      expect { run }.to(not_change { AttributeAuthorityDescriptor.count }.and(
        not_change { Tag.count }
      ).and(
        change { subject.reload.attribute_services }
      ).and(
        change { subject.reload.assertion_id_request_services }
      ).and(
        change { subject.reload.attribute_profiles }
      ).and(
        change { subject.reload.attributes }
      ))
    end
  end
end

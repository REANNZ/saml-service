# frozen_string_literal: true

RSpec.shared_examples 'ETL::IdentityProviders' do
  include_examples 'ETL::Common'

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def create_json(idp)
    contact_people =
      contact_instances.map { |cp| contact_person_json(cp) } +
      sirtfi_contact_instances.map { |cp| sirtfi_contact_person_json(cp) }

    {
      id: idp.id,
      display_name: Faker::Lorem.sentence,
      description: description,
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
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

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
                   .identity_providers(entity_descriptor, ed_data)
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
    identity_provider_instances.map { |idp| create_json(idp) }
  end

  let(:identity_providers) { identity_providers_list }

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
  end

  context 'creating an IDPSSODescriptor' do
    let(:source_idp) { identity_provider_instances.first }
    let(:idp_count) { 1 }
    let(:contact_count) { 1 }
    let(:sirtfi_contact_count) { 1 }
    let(:attribute_count) { 3 }

    subject { IDPSSODescriptor.last }

    it 'creates a new instance' do
      expect { run }.to change { IDPSSODescriptor.count }.by(idp_count)
    end

    it 'creates a new tag' do
      expect { run }
        .to change { Tag.count }.by(1)
    end

    context 'created instance' do
      before { run }

      context 'correct attributes' do
        verify(created_at: -> { idp_created_at },
               updated_at: -> { truncated_now },
               error_url: -> { source_idp.error_url },
               want_authn_requests_signed:
                 -> { source_idp.want_authn_requests_signed })
      end

      context 'scopes' do
        it 'sets a scope' do
          expect(subject.scopes.size).to eq(1)
        end

        it 'sets expected scope' do
          expect(subject.scopes.first.value).to eq(scope)
        end

        context 'normal scope' do
          it 'sets regex to false' do
            expect(subject.scopes.first.regexp).not_to be
          end
        end

        context 'regex scope' do
          let(:scope) { '^([a-zA-Z0-9-]{1,63}[.]){0,2}example.edu$' }

          it 'sets regex to true' do
            expect(subject.scopes.first.regexp).to be
          end
        end
      end

      context 'single_sign_on_services' do
        include_examples 'endpoint' do
          let(:target) { subject.single_sign_on_services }
          let(:source) { source_idp.single_sign_on_services }
        end
      end

      context 'name_id_mapping_services' do
        include_examples 'endpoint' do
          let(:target) { subject.name_id_mapping_services }
          let(:source) { source_idp.name_id_mapping_services }
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

      context 'artifact resolution services' do
        include_examples 'indexed_endpoint' do
          let(:target) { subject.artifact_resolution_services }
          let(:source) { source_idp.artifact_resolution_services }
        end
      end

      context 'single logout services' do
        include_examples 'endpoint' do
          let(:target) { subject.single_logout_services }
          let(:source) { source_idp.single_logout_services }
        end
      end

      context 'manage nameid services' do
        include_examples 'endpoint' do
          let(:target) { subject.manage_name_id_services }
          let(:source) { source_idp.manage_name_id_services }
        end
      end
    end
  end

  context 'updating an IDPSSODescriptor' do
    let(:idp_count) { 1 }
    let(:contact_count) { 1 }
    let(:sirtfi_contact_count) { 1 }
    let(:attribute_count) { 3 }

    subject { IDPSSODescriptor.last }

    before { run }

    include_examples 'updating an SSODescriptor'
    include_examples 'updating MDUI content'

    it 'uses the existing instance' do
      expect { run }.not_to(change { IDPSSODescriptor.count })
    end

    it 'sets a scope' do
      expect(subject.scopes.size).to eq(1)
    end

    it 'sets expected scope' do
      expect(subject.scopes.first.value).to eq(scope)
    end

    it 'does not create more tags' do
      expect { run }.not_to(change { Tag.count })
    end

    it 'updates single sign on services' do
      expect { run }.to(change { subject.reload.single_sign_on_services })
    end

    it 'updates name id mapping services' do
      expect { run }.to(change { subject.reload.name_id_mapping_services })
    end

    it 'updates assertion id request services' do
      expect { run }
        .to(change { subject.reload.assertion_id_request_services })
    end

    it 'updates attribute profiles' do
      expect { run }.to(change { subject.reload.attribute_profiles })
    end

    it 'updates attributes' do
      expect { run }.to(change { subject.reload.attributes })
    end
  end

  context 'updating an IDPSSODescriptor with locked scope' do
    let(:idp_count) { 1 }
    let(:contact_count) { 1 }
    let(:sirtfi_contact_count) { 1 }
    let(:attribute_count) { 3 }

    subject { IDPSSODescriptor.last }

    before do
      run
    end

    it 'retains locked scopes' do
      expect(subject.scopes.size).to eq(1)
      expect(subject.scopes.first.value).to eq(scope)

      locked_scope = create :shibmd_scope, role_descriptor: subject,
                                           locked: true
      expect(subject.scopes.size).to eq(2)

      # Run update again so we can ensure our update subject retains the
      # manually added but locked scope
      run
      expect(subject.scopes.size).to eq(2)
      expect(subject.scopes.first.value).to eq(scope)
      expect(subject.scopes.last.value).to eq(locked_scope.value)
    end
  end
end

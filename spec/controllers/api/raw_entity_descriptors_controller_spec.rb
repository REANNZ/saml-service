# frozen_string_literal: true

require 'rails_helper'

RSpec.describe API::RawEntityDescriptorsController, type: :controller do
  def unique_words(count)
    words = []
    words << Faker::Lorem.word until words.uniq.length == count
    words.uniq
  end

  describe 'patch :update' do
    let(:entity_source) { create(:entity_source) }
    let(:source_tag) { entity_source.source_tag }

    let(:tags) { unique_words(2) }
    let(:host_name) { Faker::Internet.domain_name }
    let(:entity_id_uri) { "https://#{host_name}/shibboleth" }
    let(:base64_urlsafe_entity_id) { Base64.urlsafe_encode64(entity_id_uri) }
    let(:enabled) { [true, false].sample }
    let(:edugain_enabled) { [true, false].sample }
    let(:xml) do
      <<-ENTITY.strip_heredoc
          <EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata"
            xmlns:mdui="urn:oasis:names:tc:SAML:metadata:ui"
            entityID="#{entity_id_uri}">
            <IDPSSODescriptor
              protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
              <SingleSignOnService
                Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
                Location="https://#{host_name}/idp/profile/SAML2/Redirect/SSO"/>
            </IDPSSODescriptor>
          </EntityDescriptor>
      ENTITY
    end

    let(:raw_entity_descriptor) do
      { xml: xml,
        tags: tags,
        enabled: enabled,
        edugain_enabled: edugain_enabled }
    end

    def run
      request.env['HTTP_X509_DN'] = +"CN=#{api_subject.x509_cn}" if api_subject

      patch :update, as: :json, params: {
        tag: source_tag,
        base64_urlsafe_entity_id: base64_urlsafe_entity_id,
        raw_entity_descriptor: raw_entity_descriptor
      }
    end

    def swallow
      yield
    rescue
      nil
    end

    before do
      allow(Rails.application.config)
        .to receive_message_chain(:saml_service, :api, :authentication)
        .and_return(:x509)
    end

    context 'not permitted' do
      let(:api_subject) { create(:api_subject, :x509_cn) }
      before { run }
      subject { response }
      it { is_expected.to have_http_status(:forbidden) }
      it 'responds with a message' do
        data = JSON.parse(response.body)
        expect(data['message']).to match(/explicitly denied/)
      end
    end

    context 'permitted' do
      let(:api_subject) { create(:api_subject, :x509_cn, :authorized, permission: '*') }

      subject do
        run
        response
      end

      context 'with an entity source that does not exist' do
        let(:source_tag) { Faker::Lorem.word }
        it { is_expected.to have_http_status(:not_found) }
      end

      context 'when the raw entity descriptor does not exist' do
        it { is_expected.to have_http_status(:created) }

        context 'raw entity descriptors' do
          subject { -> { run } }
          it { is_expected.to change(RawEntityDescriptor, :count).by(1) }
          context 'record' do
            before { run }
            let(:record) { RawEntityDescriptor.last }
            subject { record }
            it { is_expected.to_not be_nil }

            context 'known entity' do
              subject { record.known_entity }
              it { is_expected.to eq(KnownEntity.last) }
            end

            context 'xml' do
              subject { record.xml }
              it { is_expected.to eq(raw_entity_descriptor[:xml]) }
            end

            context 'enabled' do
              subject { record.enabled }
              it { is_expected.to eq(raw_entity_descriptor[:enabled]) }
            end

            context 'idp' do
              subject { record.idp }
              it { is_expected.to be_truthy }
            end

            context 'sp' do
              subject { record.sp }
              it { is_expected.to be_falsey }
            end

            context 'standalone aa' do
              subject { record.standalone_aa }
              it { is_expected.to be_falsey }
            end

            context 'for a service provider' do
              let(:xml) { attributes_for(:raw_entity_descriptor_sp)[:xml] }

              context 'idp' do
                subject { record.idp }
                it { is_expected.to be_falsey }
              end

              context 'sp' do
                subject { record.sp }
                it { is_expected.to be_truthy }
              end

              context 'standalone aa' do
                subject { record.standalone_aa }
                it { is_expected.to be_falsey }
              end
            end

            context 'for a standalone aa' do
              let(:xml) { attributes_for(:raw_entity_descriptor)[:xml] }

              context 'idp' do
                subject { record.idp }
                it { is_expected.to be_falsey }
              end

              context 'sp' do
                subject { record.sp }
                it { is_expected.to be_falsey }
              end

              context 'standalone aa' do
                subject { record.standalone_aa }
                it { is_expected.to be_truthy }
              end
            end
          end
        end

        context 'known entities' do
          subject { -> { run } }
          it { is_expected.to change(KnownEntity, :count).by(1) }

          context 'record' do
            before { run }
            let(:record) { KnownEntity.last }
            subject { record }
            it { is_expected.to_not be_nil }

            context 'enabled' do
              subject { record.enabled }
              it { is_expected.to eq(raw_entity_descriptor[:enabled]) }
            end

            context 'entity source' do
              subject { record.entity_source }
              it { is_expected.to eq(entity_source) }
            end

            context 'tags' do
              subject { record.tags.map(&:name) }
              let(:edugain_export_tag) do
                if edugain_enabled
                  Rails.application.config.saml_service&.api&.edugain_export_tag_name ||
                    'aaf-edugain-export'
                end
              end

              let(:all_tags) do
                tags + [source_tag, 'idp', edugain_export_tag].compact
              end

              it { is_expected.to match_array(all_tags) }
            end
          end
        end

        context 'entity ids' do
          subject { -> { run } }
          it { is_expected.to change(EntityId, :count).by(1) }

          context 'record' do
            before { run }
            let(:record) { EntityId.last }
            subject { record }
            it { is_expected.to_not be_nil }

            context 'uri' do
              subject { record.uri }
              it { is_expected.to eq(entity_id_uri) }
            end

            context 'description' do
              subject { record.description }
              it { is_expected.to be_nil }
            end

            context 'role descriptor id' do
              subject { record.role_descriptor_id }
              it { is_expected.to be_nil }
            end

            context 'entity descriptor' do
              subject { record.entity_descriptor }
              it { is_expected.to be_nil }
            end

            context 'raw entity descriptor' do
              subject { record.raw_entity_descriptor }
              it { is_expected.to eq(RawEntityDescriptor.last) }
            end

            context 'sha1' do
              subject { record.sha1 }
              it { is_expected.to eq(Digest::SHA1.hexdigest(entity_id_uri)) }
            end
          end
        end
      end

      context 'when the raw entity descriptor exists' do
        let(:original_tags) { unique_words(2) }
        let(:original_host_name) { Faker::Internet.domain_name }
        let(:original_enabled) { [true, false].sample }
        let(:original_xml) do
          <<-ENTITY.strip_heredoc
            <EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata"
              xmlns:mdui="urn:oasis:names:tc:SAML:metadata:ui"
              entityID="#{entity_id_uri}">
              <IDPSSODescriptor
             protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
                <SingleSignOnService
                  Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
       Location="https://#{original_host_name}/idp/profile/SAML2/Redirect/SSO"/>
              </IDPSSODescriptor>
            </EntityDescriptor>
          ENTITY
        end

        let(:original_known_entity) do
          create(:known_entity, entity_source: entity_source,
                                enabled: original_enabled)
        end

        let(:original_raw_entity_descriptor) do
          create(:raw_entity_descriptor, known_entity: original_known_entity,
                                         xml: original_xml, idp: true)
        end

        before do
          EntityId.create(uri: entity_id_uri,
                          raw_entity_descriptor: original_raw_entity_descriptor)
          original_tags.each { |t| original_known_entity.tag_as(t) }
        end

        it { is_expected.to have_http_status(:no_content) }

        context 'raw entity descriptors' do
          subject { -> { run } }
          it { is_expected.to_not change(RawEntityDescriptor, :count) }

          context 'record' do
            before { run }
            let(:record) { RawEntityDescriptor.last }

            subject { record }

            context 'xml' do
              subject { record.xml }

              it 'has been updated' do
                expect(subject).to eq(xml)
              end
            end

            context 'enabled' do
              subject { record.enabled }

              it 'has been updated' do
                expect(subject).to eq(enabled)
              end
            end

            context 'idp' do
              subject { record.idp }
              it { is_expected.to be_truthy }
            end

            context 'sp' do
              subject { record.sp }
              it { is_expected.to be_falsey }
            end

            context 'standalone aa' do
              subject { record.standalone_aa }
              it { is_expected.to be_falsey }
            end

            context 'for a service provider' do
              let(:xml) { attributes_for(:raw_entity_descriptor_sp)[:xml] }

              context 'idp' do
                subject { record.idp }
                it { is_expected.to be_falsey }
              end

              context 'sp' do
                subject { record.sp }
                it { is_expected.to be_truthy }
              end

              context 'standalone aa' do
                subject { record.standalone_aa }
                it { is_expected.to be_falsey }
              end
            end

            context 'for a standalone aa' do
              let(:xml) { attributes_for(:raw_entity_descriptor)[:xml] }

              context 'idp' do
                subject { record.idp }
                it { is_expected.to be_falsey }
              end

              context 'sp' do
                subject { record.sp }
                it { is_expected.to be_falsey }
              end

              context 'standalone aa' do
                subject { record.standalone_aa }
                it { is_expected.to be_truthy }
              end
            end
          end
        end

        context 'known entity' do
          subject { -> { run } }
          it { is_expected.to_not change(KnownEntity, :count) }

          it 'invalidates the MDQ cache' do
            run
            Timecop.travel(1.second) do
              expect { run }.to(change { KnownEntity.last.updated_at })
            end
          end

          context 'record' do
            before { run }
            let(:record) { KnownEntity.last }
            subject { record }

            context 'enabled' do
              subject { record.enabled }

              it 'has been updated' do
                expect(subject).to eq(enabled)
              end
            end

            context 'entity source' do
              let(:entity_source_record) { record.entity_source }

              context 'id' do
                subject { entity_source_record.id }
                it 'has not changed' do
                  expect(subject).to eq(entity_source.id)
                end
              end
            end

            context 'tags' do
              subject { record.tags.map(&:name) }
              let(:new_tags) { tags.append(source_tag) }

              let(:edugain_export_tag) do
                if edugain_enabled
                  Rails.application.config.saml_service&.api&.edugain_export_tag_name ||
                    'aaf-edugain-export'
                end
              end

              let(:all_tags) do
                new_tags + original_tags + ['idp', edugain_export_tag].compact
              end

              it 'appends the new tags' do
                expect(subject).to match_array(all_tags)
              end
            end
          end
        end

        context 'entity id' do
          subject { -> { run } }
          it { is_expected.to_not change(EntityId, :count) }

          context 'record' do
            before { run }
            let(:record) { EntityId.last }
            subject { record }

            context 'uri' do
              subject { record.uri }

              it 'has not changed' do
                expect(subject).to eq(entity_id_uri)
              end
            end

            context 'description' do
              subject { record.description }
              it { is_expected.to be_nil }
            end

            context 'role descriptor id' do
              subject { record.role_descriptor_id }
              it { is_expected.to be_nil }
            end

            context 'entity descriptor' do
              subject { record.entity_descriptor }
              it { is_expected.to be_nil }
            end

            context 'raw entity descriptor' do
              let(:raw_entity_descriptor_record) do
                record.raw_entity_descriptor
              end

              context 'id' do
                subject { raw_entity_descriptor_record.id }
                it 'has not changed' do
                  expect(subject).to eq(original_raw_entity_descriptor.id)
                end
              end
            end

            context 'sha1' do
              subject { record.sha1 }
              it { is_expected.to eq(Digest::SHA1.hexdigest(entity_id_uri)) }
            end
          end
        end
      end

      RSpec.shared_examples 'no state changed' do
        subject { -> { swallow { run } } }

        context 'known entities' do
          it { is_expected.to_not change(KnownEntity, :count) }
        end

        context 'raw entity descriptors' do
          it { is_expected.to_not change(RawEntityDescriptor, :count) }
        end

        context 'entity ids' do
          it { is_expected.to_not change(EntityId, :count) }
        end
      end

      context 'with empty raw entity descriptor' do
        let(:raw_entity_descriptor) { {} }
        subject { -> { run } }

        it { is_expected.to raise_error(ActionController::ParameterMissing) }
        it_behaves_like 'no state changed'
      end

      context 'with missing xml' do
        before { raw_entity_descriptor.delete(:xml) }
        subject { -> { run } }
        let(:message) { /xml is not present/ }

        it { is_expected.to raise_error(Sequel::ValidationFailed, message) }
        it_behaves_like 'no state changed'
      end

      context 'with an invalid base64 urlsafe entity id' do
        let(:base64_urlsafe_entity_id) { Faker::Lorem.sentence }
        subject { -> { run } }
        let(:message) { /invalid base64/ }

        it { is_expected.to raise_error(ArgumentError, message) }
        it_behaves_like 'no state changed'
      end

      context 'with missing enabled flag' do
        before { raw_entity_descriptor.delete(:enabled) }

        it { is_expected.to have_http_status(:bad_request) }
        it_behaves_like 'no state changed'
      end

      context 'with missing tags' do
        before { raw_entity_descriptor.delete(:tags) }

        it { is_expected.to have_http_status(:bad_request) }
        it_behaves_like 'no state changed'
      end

      context 'with an invalid enabled flag' do
        let(:enabled) { Faker::Lorem.characters }

        it { is_expected.to have_http_status(:bad_request) }
        it_behaves_like 'no state changed'
      end

      context 'with an invalid edugain enabled flag' do
        let(:edugain_enabled) { Faker::Lorem.characters }

        it { is_expected.to have_http_status(:bad_request) }
        it_behaves_like 'no state changed'
      end

      context 'with invalid entity id uri' do
        let(:entity_id_uri) { '' }
        subject { -> { run } }
        let(:message) { /uri is not present/ }

        it { is_expected.to raise_error(Sequel::ValidationFailed, message) }
        it_behaves_like 'no state changed'
      end

      context 'with invalid tags' do
        let(:tags) { ['@*!', '^'] }
        subject { -> { run } }
        let(:message) { /name is not in base64 urlsafe alphabet/ }

        it { is_expected.to raise_error(Sequel::ValidationFailed, message) }
        it_behaves_like 'no state changed'
      end

      context 'with invalid xml' do
        subject { -> { run } }
        let(:xml) do
          <<-ENTITY.strip_heredoc
            <IDPSSODescriptor
              protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
              <SingleSignOnService
                Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
                Location="https://#{host_name}/idp/profile/SAML2/Redirect/SSO"/>
            </IDPSSODescriptor>
          ENTITY
        end

        let(:message) { /xml is not valid per the XML Schema/ }

        it { is_expected.to raise_error(Sequel::ValidationFailed, message) }
        it_behaves_like 'no state changed'
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe API::DiscoveryEntitiesController, type: :controller do
  let(:api_subject) { create(:api_subject, :x509_cn, :authorized, permission: '*') }

  let!(:entity_source) { create(:entity_source, rank: rand(1..10)) }

  let(:idp_known_entity) do
    create(:known_entity, entity_source: entity_source)
  end

  let(:raw_ed_idp_known_entity) do
    create(:known_entity, entity_source: entity_source)
  end

  let!(:identity_provider) do
    create(:entity_descriptor, known_entity: idp_known_entity)
  end

  let!(:idp_sso_descriptor) do
    create(:idp_sso_descriptor, entity_descriptor: identity_provider)
  end

  let!(:raw_ed_idp) do
    create(:raw_entity_descriptor_idp, known_entity: raw_ed_idp_known_entity)
  end

  let(:sp_known_entity) { create(:known_entity, entity_source: entity_source) }

  let!(:service_provider) do
    create(:entity_descriptor, known_entity: sp_known_entity)
  end

  let(:raw_ed_sp_known_entity) do
    create(:known_entity, entity_source: entity_source)
  end

  let!(:raw_ed_sp) do
    create(:raw_entity_descriptor_sp, known_entity: raw_ed_sp_known_entity)
  end

  let!(:sp_sso_descriptor) do
    create(:sp_sso_descriptor, entity_descriptor: service_provider)
  end

  let!(:other_identity_provider) {}
  let!(:other_idp_sso_descriptor) {}
  let!(:other_raw_ed_idp) {}

  let!(:other_service_provider) {}
  let!(:other_sp_sso_descriptor) {}
  let!(:other_raw_ed_sp) {}

  before do
    request.env['HTTP_X509_DN'] = +"CN=#{api_subject.x509_cn}" if api_subject
  end

  describe 'get :index' do
    before { get :index, format: :json }

    subject { response }

    it { is_expected.to have_http_status(:ok) }
    it { is_expected.to render_template('api/discovery_entities/index') }

    it 'assigns the identity providers' do
      expect(assigns[:identity_provider_entities])
        .to include(identity_provider)
        .and include(raw_ed_idp)
        .and not_include(service_provider)
        .and not_include(raw_ed_sp)
    end

    context 'for a disabled identity provider' do
      let!(:identity_provider) { create(:entity_descriptor, enabled: false) }

      it 'excludes the identity provider' do
        expect(assigns[:identity_provider_entities])
          .not_to include(identity_provider)
      end

      it 'has no nil values' do
        expect(assigns[:identity_provider_entities])
          .not_to include(nil)
      end
    end

    context 'for a disabled raw entity descriptor - idp' do
      let!(:raw_ed_idp) do
        create(:raw_entity_descriptor_idp, enabled: false)
      end

      it 'excludes the identity provider' do
        expect(assigns[:identity_provider_entities])
          .not_to include(raw_ed_idp)
      end

      it 'has no nil values' do
        expect(assigns[:identity_provider_entities])
          .not_to include(nil)
      end
    end

    it 'assigns the service providers' do
      expect(assigns[:service_provider_entities])
        .to include(service_provider)
        .and include(raw_ed_sp)
        .and not_include(identity_provider)
        .and not_include(raw_ed_idp)
    end

    context 'for a disabled service provider' do
      let!(:service_provider) { create(:entity_descriptor, enabled: false) }

      it 'excludes the service provider' do
        expect(assigns[:service_provider_entities])
          .not_to include(service_provider)
      end

      it 'has no nil values' do
        expect(assigns[:service_provider_entities])
          .not_to include(nil)
      end
    end

    context 'for a disabled raw entity descriptor - sp' do
      let!(:raw_ed_sp) do
        create(:raw_entity_descriptor_sp, enabled: false)
      end

      it 'excludes the service provider' do
        expect(assigns[:service_provider_entities])
          .not_to include(raw_ed_sp)
      end

      it 'has no nil values' do
        expect(assigns[:service_provider_entities])
          .not_to include(nil)
      end
    end

    context 'with other entity source' do
      let!(:other_entity_source) { create(:entity_source, rank: other_rank) }

      let!(:other_idp_enabled) { false }
      let!(:other_sp_enabled) { false }

      let!(:other_idp_known_entity) do
        create(:known_entity, entity_source: other_entity_source,
                              enabled: other_idp_enabled)
      end

      let!(:other_sp_known_entity) do
        create(:known_entity, entity_source: other_entity_source,
                              enabled: other_sp_enabled)
      end

      context 'other ed-idp same entity id as existing ed-idp' do
        let!(:other_identity_provider) do
          other = create(:entity_descriptor,
                         known_entity: other_idp_known_entity,
                         enabled: other_idp_enabled)
          other.entity_id.update(uri: identity_provider.entity_id.uri)
          other
        end

        let!(:other_idp_sso_descriptor) do
          create(:idp_sso_descriptor,
                 entity_descriptor: other_identity_provider)
        end

        context 'other has lower rank' do
          let!(:other_rank) { entity_source.rank - 1 }

          context 'but not functional' do
            let!(:other_idp_enabled) { false }

            it 'includes existing, ignores other' do
              expect(assigns[:identity_provider_entities])
                .to include(identity_provider)
                .and not_include(other_identity_provider)
            end
          end

          context 'and is functional' do
            let!(:other_idp_enabled) { true }

            it 'includes other, ignores existing' do
              expect(assigns[:identity_provider_entities])
                .to include(other_identity_provider)
                .and not_include(identity_provider)
            end
          end
        end

        context 'other has higher rank' do
          let!(:other_rank) { entity_source.rank + 1 }

          context 'but not functional' do
            let!(:other_idp_enabled) { false }

            it 'includes existing, ignores other' do
              expect(assigns[:identity_provider_entities])
                .to include(identity_provider)
                .and not_include(other_identity_provider)
            end
          end

          context 'and is functional' do
            let!(:other_idp_enabled) { true }

            it 'includes existing, ignores other' do
              expect(assigns[:identity_provider_entities])
                .to include(identity_provider)
                .and not_include(other_identity_provider)
            end
          end
        end
      end

      context 'other rad-idp with same entity id as rad-idp' do
        let!(:other_raw_ed_idp) do
          other = create(:raw_entity_descriptor_idp,
                         known_entity: other_idp_known_entity,
                         enabled: other_idp_enabled,
                         idp: true)
          other.entity_id.update(uri: raw_ed_idp.entity_id.uri)
          other
        end

        context 'other has lower rank' do
          let!(:other_rank) { entity_source.rank - 1 }

          context 'but not functional' do
            let!(:other_idp_enabled) { false }

            it 'includes existing, ignores other' do
              expect(assigns[:identity_provider_entities])
                .to include(raw_ed_idp)
                .and not_include(other_raw_ed_idp)
            end
          end

          context 'and is functional' do
            let!(:other_idp_enabled) { true }

            it 'includes other, ignores existing' do
              expect(assigns[:identity_provider_entities])
                .to include(other_raw_ed_idp)
                .and not_include(raw_ed_idp)
            end
          end
        end

        context 'other has higher rank' do
          let!(:other_rank) { entity_source.rank + 1 }

          context 'but not functional' do
            let!(:other_idp_enabled) { false }

            it 'includes existing, ignores other' do
              expect(assigns[:identity_provider_entities])
                .to include(raw_ed_idp)
                .and not_include(other_raw_ed_idp)
            end
          end

          context 'and is functional' do
            let!(:other_idp_enabled) { true }

            it 'includes existing, ignores other' do
              expect(assigns[:identity_provider_entities])
                .to include(raw_ed_idp)
                .and not_include(other_raw_ed_idp)
            end
          end
        end
      end

      context 'rad-idp with same entity id as ed-idp' do
        let!(:other_raw_ed_idp) do
          other = create(:raw_entity_descriptor_idp,
                         known_entity: other_idp_known_entity,
                         enabled: other_idp_enabled,
                         idp: true)
          other.entity_id.update(uri: identity_provider.entity_id.uri)
          other
        end

        context 'rad-idp has lower rank than ed-idp' do
          let!(:other_rank) { entity_source.rank - 1 }

          context 'but rad-idp not functional' do
            let!(:other_idp_enabled) { false }

            it 'includes ed-idp, ignores rad-idp' do
              expect(assigns[:identity_provider_entities])
                .to include(identity_provider)
                .and not_include(other_raw_ed_idp)
            end
          end

          context 'and rad-idp is functional' do
            let!(:other_idp_enabled) { true }

            it 'includes rad-idp, ignores ed-idp' do
              expect(assigns[:identity_provider_entities])
                .to include(other_raw_ed_idp)
                .and not_include(identity_provider)
            end
          end
        end

        context 'rad-idp has higher rank than ed-idp' do
          let!(:other_rank) { entity_source.rank + 1 }

          context 'but rad-idp not functional' do
            let!(:other_idp_enabled) { false }

            it 'includes ed-idp, ignores rad-idp' do
              expect(assigns[:identity_provider_entities])
                .to include(identity_provider)
                .and not_include(other_raw_ed_idp)
            end
          end

          context 'and rad-idp is functional' do
            let!(:other_idp_enabled) { true }

            it 'includes ed-idp, ignores rad-idp' do
              expect(assigns[:identity_provider_entities])
                .to include(raw_ed_idp)
                .and not_include(other_raw_ed_idp)
            end
          end
        end
      end

      context 'other ed-sp same entity id as existing ed-sp' do
        let!(:other_service_provider) do
          other = create(:entity_descriptor,
                         known_entity: other_sp_known_entity,
                         enabled: other_sp_enabled)
          other.entity_id.update(uri: service_provider.entity_id.uri)
          other
        end

        let!(:other_sp_sso_descriptor) do
          create(:sp_sso_descriptor,
                 entity_descriptor: other_service_provider)
        end

        context 'other has lower rank' do
          let!(:other_rank) { entity_source.rank - 1 }

          context 'but not functional' do
            let!(:other_sp_enabled) { false }

            it 'includes existing, ignores other' do
              expect(assigns[:service_provider_entities])
                .to include(service_provider)
                .and not_include(other_service_provider)
            end
          end

          context 'and other is functional' do
            let!(:other_sp_enabled) { true }

            it 'includes other, ignores existing' do
              expect(assigns[:service_provider_entities])
                .to include(other_service_provider)
                .and not_include(service_provider)
            end
          end
        end

        context 'other has higher rank' do
          let!(:other_rank) { entity_source.rank + 1 }

          context 'but not functional' do
            let!(:other_sp_enabled) { false }

            it 'includes existing, ignores other' do
              expect(assigns[:service_provider_entities])
                .to include(service_provider)
                .and not_include(other_service_provider)
            end
          end

          context 'and is functional' do
            let!(:other_sp_enabled) { true }

            it 'includes existing, ignores other' do
              expect(assigns[:service_provider_entities])
                .to include(service_provider)
                .and not_include(other_service_provider)
            end
          end
        end
      end

      context 'other rad-sp with same entity id as rad-sp' do
        let!(:other_raw_ed_sp) do
          other = create(:raw_entity_descriptor_sp,
                         known_entity: other_sp_known_entity,
                         enabled: other_sp_enabled,
                         sp: true)
          other.entity_id.update(uri: raw_ed_sp.entity_id.uri)
          other
        end

        context 'other has lower rank' do
          let!(:other_rank) { entity_source.rank - 1 }

          context 'but not functional' do
            let!(:other_sp_enabled) { false }

            it 'includes existing, ignores other' do
              expect(assigns[:service_provider_entities])
                .to include(raw_ed_sp)
                .and not_include(other_raw_ed_sp)
            end
          end

          context 'and is functional' do
            let!(:other_sp_enabled) { true }

            it 'includes other, ignores existing' do
              expect(assigns[:service_provider_entities])
                .to include(other_raw_ed_sp)
                .and not_include(raw_ed_sp)
            end
          end
        end

        context 'other has higher rank' do
          let!(:other_rank) { entity_source.rank + 1 }

          context 'but not functional' do
            let!(:other_sp_enabled) { false }

            it 'includes existing, ignores other' do
              expect(assigns[:service_provider_entities])
                .to include(raw_ed_sp)
                .and not_include(other_raw_ed_sp)
            end
          end

          context 'and is functional' do
            let!(:other_sp_enabled) { true }

            it 'includes existing, ignores other' do
              expect(assigns[:service_provider_entities])
                .to include(raw_ed_sp)
                .and not_include(other_raw_ed_sp)
            end
          end
        end
      end

      context 'other rad-sp with same entity id as ed-sp' do
        let!(:other_raw_ed_sp) do
          other = create(:raw_entity_descriptor_sp,
                         known_entity: other_sp_known_entity,
                         enabled: other_sp_enabled,
                         sp: true)
          other.entity_id.update(uri: service_provider.entity_id.uri)
          other
        end

        context 'rad-sp has lower rank than ed-sp' do
          let!(:other_rank) { entity_source.rank - 1 }

          context 'but not functional' do
            let!(:other_sp_enabled) { false }

            it 'includes ed-sp, ignores rad-sp' do
              expect(assigns[:service_provider_entities])
                .to include(service_provider)
                .and not_include(other_raw_ed_sp)
            end
          end

          context 'and is functional' do
            let!(:other_sp_enabled) { true }

            it 'includes rad-sp, ignores ed-sp' do
              expect(assigns[:service_provider_entities])
                .to include(other_raw_ed_sp)
                .and not_include(service_provider)
            end
          end
        end

        context 'rad-sp has higher rank than ed-sp' do
          let!(:other_rank) { entity_source.rank + 1 }

          context 'but not functional' do
            let!(:other_sp_enabled) { false }

            it 'includes ed-sp, ignores rad-sp' do
              expect(assigns[:service_provider_entities])
                .to include(service_provider)
                .and not_include(other_raw_ed_sp)
            end
          end

          context 'and is functional' do
            let!(:other_sp_enabled) { true }

            it 'includes ed-sp, ignores rad-sp' do
              expect(assigns[:service_provider_entities])
                .to include(service_provider)
                .and not_include(other_raw_ed_sp)
            end
          end
        end
      end
    end

    context 'with no permissions' do
      let(:api_subject) { create(:api_subject, :x509_cn) }

      it { is_expected.to have_http_status(:ok) }
      it { is_expected.to render_template('api/discovery_entities/index') }
    end

    context 'when unauthenticated' do
      let(:api_subject) { nil }

      it { is_expected.to have_http_status(:ok) }
      it { is_expected.to render_template('api/discovery_entities/index') }
    end
  end
end

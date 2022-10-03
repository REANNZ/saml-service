# frozen_string_literal: true

require 'rails_helper'

RSpec.describe API::DiscoveryEntitiesController, type: :request do
  subject { response }

  let(:json) { JSON.parse(response.body, symbolize_names: true) }

  shared_examples 'a discovery entity' do
    it 'includes the entity id' do
      expect(subject.pluck(:entity_id))
        .to include(entity.entity_id.uri)
    end

    context 'with no tags' do
      it 'returns an empty tag list' do
        expect(entry[:tags]).to eq([])
      end
    end

    context 'with tags on the known entity' do
      let!(:tags) do
        %w[tag_a tag_b tag_c].map do |tag|
          create(:known_entity_tag,
                 name: tag, known_entity: entity.known_entity)
        end
      end

      it 'returns the tags' do
        expect(entry[:tags]).to contain_exactly('tag_a', 'tag_b', 'tag_c')
      end
    end

    context 'with no mdui info' do
      it 'includes an empty list of display names' do
        expect(entry[:names]).to eq([])
      end

      it 'includes an empty list of logos' do
        expect(entry[:logos]).to eq([])
      end

      it 'includes an empty list of descriptions' do
        expect(entry[:descriptions]).to eq([])
      end
    end

    context 'with mdui info' do
      let!(:ui_info) do
        create(:mdui_ui_info, :with_content, role_descriptor: role_descriptor)
      end

      it 'includes the display names' do
        display_name = role_descriptor.ui_info.display_names.first
        expect(entry[:names])
          .to include(value: display_name.value, lang: display_name.lang)
      end

      it 'includes the logo uri' do
        logo = role_descriptor.ui_info.logos.first
        expect(entry[:logos]).to include(url: logo.uri, lang: logo.lang,
                                         width: logo.width, height: logo.height)
      end

      it 'includes the descriptions' do
        description = role_descriptor.ui_info.descriptions.first
        expect(entry[:descriptions])
          .to include(value: description.value, lang: description.lang)
      end
    end
  end

  context 'get /api/discovery/entities' do
    def run
      get '/api/discovery/entities', headers: headers
    end

    context 'response' do
      before { run }

      it { is_expected.to have_http_status(:ok) }
    end

    # {
    #   "identity_providers":[
    #     {
    #       "entity_id": "https://idp.example.edu/idp/shibboleth",
    #       "names":[
    #         {
    #           "value":"Example University",
    #           "lang":"en"
    #         }
    #       ],
    #       "tags":[
    #         "discovery",
    #         "aaf"
    #       ],
    #       "logos": [
    #         {
    #           "url": "https://example.edu/static/logo.jpg",
    #           "lang": "en"
    #         }
    #       ],
    #       "descriptions": [
    #         {
    #           "value": "Example University is a university for examples",
    #           "lang": "en"
    #         }
    #       ],
    #       "geolocations" : [{ "longitude": 26.38695, "latitude": 69.395142 }],
    #       "domains" : ["example.edu"]
    #     }
    #   ]
    # }
    context 'identity_providers' do
      let!(:identity_providers) { create_list(:entity_descriptor, 1) }

      let!(:idp_sso_descriptors) do
        identity_providers.map do |ed|
          create(:idp_sso_descriptor, entity_descriptor: ed)
        end
      end

      let(:entity) { identity_providers.first }
      let(:role_descriptor) { entity.idp_sso_descriptors.first }

      let(:entry) do
        subject.find do |idp|
          idp[:entity_id] == entity.entity_id.uri
        end
      end

      let!(:tags) { [] }
      let!(:ui_info) { nil }

      before { run }

      subject { json[:identity_providers] }

      it_behaves_like 'a discovery entity'

      context 'with no soap SSO endpoints' do
        it 'includes an empty list of soap endpoint data' do
          expect(entry[:single_sign_on_endpoints][:soap]).to eq([])
        end
      end

      context 'with soap SSO endpoints' do
        let(:ecp_location) { Faker::Internet.url }
        let!(:idp_sso_descriptors) do
          identity_providers.map do |ed|
            idp = create(:idp_sso_descriptor, entity_descriptor: ed)
            SingleSignOnService.create(
              binding: 'urn:oasis:names:tc:SAML:2.0:bindings:SOAP',
              location: ecp_location,
              idp_sso_descriptor: idp
            )
          end
        end

        it 'includes soap endpoints' do
          expect(entry[:single_sign_on_endpoints][:soap])
            .to contain_exactly(ecp_location)
        end
      end

      context 'with no disco hints' do
        it 'includes an empty list of geolocation data' do
          expect(entry[:geolocations]).to eq([])
        end

        it 'includes an empty list of domain hints' do
          expect(entry[:domains]).to eq([])
        end
      end

      context 'with disco hints' do
        let!(:idp_sso_descriptors) do
          identity_providers.map do |idp|
            create(:idp_sso_descriptor, :with_disco_hints,
                   entity_descriptor: idp).tap do |rd|
              create(:mdui_geolocation_hint, disco_hints: rd.disco_hints)
            end
          end
        end

        it 'includes the geolocation data' do
          geo = role_descriptor.disco_hints.geolocation_hints.first.uri
          match = geo.match(/^geo:(?<lat>[\d.]+),(?<long>[\d.]+)/)
          expect(entry[:geolocations])
            .to include(latitude: match[:lat], longitude: match[:long])
        end

        context 'when geolocation data includes altitude' do
          let!(:idp_sso_descriptors) do
            identity_providers.map do |idp|
              create(:idp_sso_descriptor, entity_descriptor: idp).tap do |rd|
                disco_hints = create(:mdui_disco_hint, idp_sso_descriptor: rd)
                create(:mdui_geolocation_hint, :with_altitude,
                       disco_hints: disco_hints)
              end
            end
          end

          it 'includes the geolocation data' do
            geo = role_descriptor.disco_hints.geolocation_hints.first.uri
            regexp = /^geo:(?<lat>[\d.]+),(?<long>[\d.]+),(?<alt>[\d.]+)/
            match = geo.match(regexp)

            expect(entry[:geolocations])
              .to include(latitude: match[:lat], longitude: match[:long],
                          altitude: match[:alt])
          end
        end

        it 'includes the domain hints' do
          domain = role_descriptor.disco_hints.domain_hints.first.domain
          expect(entry[:domains]).to include(domain)
        end
      end
    end

    # "service_providers":[
    #   {
    #     "entity_id":"https://example.edu/shibboleth",
    #     "discovery_response":"https://example.edu/Shibboleth.sso/Login",
    #     "all_discovery_response_endpoints: [
    #       "https://example.edu/Shibboleth.sso/Login",
    #       "https://example.edu/Shibboleth.sso/AnotherLogin",
    #       "https://example.edu/Shibboleth.sso/YetAnotherLogin"
    #     ],
    #     "names":[
    #       {
    #         "value":"Example University SP",
    #         "lang":"en"
    #       }
    #     ],
    #     "tags":[
    #       "aaf"
    #     ],
    #     "logos": [
    #       {
    #         "url": "https://example.edu/static/logo.png",
    #         "lang": "en"
    #       }
    #     ],
    #     "descriptions": [
    #       {
    #         "value": "Example University federated service",
    #         "lang": "en"
    #       }
    #     ],
    #     "information_urls": [
    #       {
    #         "url": "https://example.edu/info",
    #         "lang": "en"
    #       }
    #     ],
    #     "privacy_statement_urls": [
    #       {
    #         "url": "https://example.edu/privacy",
    #         "lang": "en"
    #       }
    #     ]
    #   },
    #   ...
    # ]
    context 'service_providers' do
      let!(:service_providers) { create_list(:entity_descriptor, 1) }

      let!(:sp_sso_descriptors) do
        service_providers.map do |sp|
          create(:sp_sso_descriptor, entity_descriptor: sp)
        end
      end

      let(:entity) { service_providers.first }
      let(:role_descriptor) { entity.sp_sso_descriptors.first }

      let(:entry) do
        subject.find do |sp|
          sp[:entity_id] == entity.entity_id.uri
        end
      end

      let!(:tags) { [] }
      let!(:ui_info) { nil }
      let!(:discovery_response_services) { [] }

      before { run }

      subject { json[:service_providers] }

      it_behaves_like 'a discovery entity'

      context 'with discovery response services' do
        context 'with a default' do
          let(:non_default) do
            create(:discovery_response_service,
                   is_default: false, sp_sso_descriptor: role_descriptor)
          end

          let(:default) do
            create(:discovery_response_service,
                   is_default: true, sp_sso_descriptor: role_descriptor)
          end

          let!(:discovery_response_services) do
            non_default
            default
          end

          it 'includes the default discovery response location' do
            expect(entry[:discovery_response]).to eq(default.location)
          end

          context 'when multiple defaults exist' do
            let(:second_default) do
              create(:discovery_response_service,
                     is_default: true, sp_sso_descriptor: role_descriptor)
            end

            let!(:discovery_response_services) do
              non_default
              default
              second_default
            end

            it 'includes the "first" default' do
              expect(entry[:discovery_response]).to eq(default.location)
            end

            it 'lists all the endpoints' do
              endpoints = [non_default, default, second_default].map(&:location)
              expect(entry[:all_discovery_response_endpoints])
                .to contain_exactly(*endpoints)
            end
          end
        end

        context 'with no default' do
          let(:preferred) do
            create(:discovery_response_service,
                   is_default: false, sp_sso_descriptor: role_descriptor)
          end

          let(:non_preferred) do
            create(:discovery_response_service,
                   is_default: false, sp_sso_descriptor: role_descriptor)
          end

          let!(:discovery_response_services) do
            preferred
            non_preferred
          end

          it 'includes the preferred endpoint' do
            expect(entry[:discovery_response]).to eq(preferred.location)
          end

          it 'lists all the endpoints' do
            endpoints = [preferred, non_preferred].map(&:location)
            expect(entry[:all_discovery_response_endpoints])
              .to contain_exactly(*endpoints)
          end
        end
      end

      context 'with no mdui info' do
        it 'includes an empty list of information urls' do
          expect(entry[:information_urls]).to eq([])
        end

        it 'includes an empty list of privacy statement urls' do
          expect(entry[:privacy_statement_urls]).to eq([])
        end
      end

      context 'with mdui info' do
        let!(:ui_info) do
          create(:mdui_ui_info, :with_content, role_descriptor: role_descriptor)
        end

        it 'includes the information urls' do
          info_url = role_descriptor.ui_info.information_urls.first
          expect(entry[:information_urls])
            .to include(url: info_url.uri, lang: info_url.lang)
        end

        it 'includes the information urls' do
          privacy_url = role_descriptor.ui_info.privacy_statement_urls.first
          expect(entry[:privacy_statement_urls])
            .to include(url: privacy_url.uri, lang: privacy_url.lang)
        end
      end
    end
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :raw_entity_descriptor do
    transient do
      hostname { "raw.#{Faker::Internet.domain_name}" }
      entity_id_uri { "https://#{hostname}/shibboleth" }
    end

    enabled { true }

    association :known_entity
    transient do
      namespace { nil }
      entitity_descriptor_opener do
        <<~ENTITY.strip
          <#{namespace}EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata"
          xmlns:mdui="urn:oasis:names:tc:SAML:metadata:ui"
          entityID="#{entity_id_uri}">
        ENTITY
      end

      discovery_response { nil }

      sequence(:ui_info) do |n|
        <<~ENTITY.strip
          <mdui:UIInfo>
            <mdui:DisplayName xml:lang="en">
              #{Faker::Lorem.word}
            </mdui:DisplayName>
            <mdui:Description xml:lang="en">
               #{n} #{Faker::Lorem.sentence} (raw)
            </mdui:Description>
            <mdui:Logo height="16" width="16">
                https://example.edu/img.png
            </mdui:Logo>
            <mdui:InformationURL xml:lang="en">
              #{Faker::Internet.url}
            </mdui:InformationURL>
            <mdui:PrivacyStatementURL xml:lang="en">
              #{Faker::Internet.url}
            </mdui:PrivacyStatementURL>
          </mdui:UIInfo>
        ENTITY
      end

      disco_hints do
        <<~ENTITY.strip
            <mdui:DiscoHints>
            <mdui:IPHint>2001:620::0/96</mdui:IPHint>
            <mdui:DomainHint>example.edu</mdui:DomainHint>
            <mdui:GeolocationHint>geo:47.37328,8.531126</mdui:GeolocationHint>
          </mdui:DiscoHints>
        ENTITY
      end

      final_descriptor do
        <<~ENTITY.strip
          <#{namespace}AttributeAuthorityDescriptor
          protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
            <#{namespace}AttributeService
                Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
                Location="https://#{hostname}/idp/profile/AttributeQuery/SOAP"/>
          </#{namespace}AttributeAuthorityDescriptor>
        ENTITY
      end
    end

    xml do
      <<~ENTITY.strip
          #{entitity_descriptor_opener}
          <#{namespace}Extensions>
            #{discovery_response}
            #{ui_info}
            #{disco_hints}
          </#{namespace}Extensions>
          #{final_descriptor}
        </#{namespace}EntityDescriptor>
      ENTITY
    end

    trait :without_ui_info do
      transient do
        ui_info { nil }
      end
    end

    trait :without_disco_hints do
      transient do
        disco_hints { nil }
      end
    end

    after :create do |red, eval|
      red.entity_id = create :raw_entity_id, uri: eval.entity_id_uri,
                                             raw_entity_descriptor: red
    end

    factory :raw_entity_descriptor_idp do
      idp { true }

      transient do
        final_descriptor do
          <<~ENTITY.strip
            <IDPSSODescriptor
              protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
              <SingleSignOnService
                Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
                Location="https://#{hostname}/idp/profile/SAML2/Redirect/SSO"/>
            </IDPSSODescriptor>
          ENTITY
        end
      end
    end

    factory :raw_entity_descriptor_sp do
      sp { true }

      transient do
        final_descriptor do
          <<~ENTITY.strip
            <SPSSODescriptor
            protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
              <AssertionConsumerService
                Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
                Location="https://#{hostname}/Shibboleth.sso/SAML2/POST"
                index="1" isDefault="true" />
            </SPSSODescriptor>
          ENTITY
        end
        entitity_descriptor_opener do
          <<~ENTITY.strip
            <EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata"
              xmlns:idpdisc=
                "urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol"
              xmlns:mdui="urn:oasis:names:tc:SAML:metadata:ui"
              entityID="#{entity_id_uri}">
          ENTITY
        end
        discovery_response do
          <<~ENTITY.strip
            <idpdisc:DiscoveryResponse
              Binding=
                "urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol"
              Location=
                "https://#{hostname}/Shibboleth.sso/Login"
              index="1" isDefault="true" />
          ENTITY
        end
      end

      trait :without_discovery_response do
        transient do
          discovery_response { nil }
        end
      end
    end

    factory :raw_entity_descriptor_invalid_geo_location do
      transient do
        hostname { "raw.#{Faker::Internet.domain_name}" }
        entity_id_uri { "https://#{hostname}/shibboleth" }
      end

      enabled { true }

      association :known_entity

      transient do
        disco_hints do
          <<~ENTITY.strip
            <mdui:DiscoHints>
              <mdui:IPHint>2001:620::0/96</mdui:IPHint>
              <mdui:DomainHint>example.edu</mdui:DomainHint>
              <mdui:GeolocationHint>
                geo:47.37328,8.531126
              </mdui:GeolocationHint>
              <mdui:GeolocationHint>
                http://invalid.example.com
              </mdui:GeolocationHint>
            </mdui:DiscoHints>
          ENTITY
        end

        final_descriptor do
          <<~ENTITY.strip
            <AttributeAuthorityDescriptor
              protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
              <AttributeService
                Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
                Location="https://#{hostname}/idp/profile/AttributeQuery/SOAP"/>
            </AttributeAuthorityDescriptor>
          ENTITY
        end
      end
    end

    factory :raw_entity_descriptor_xyz_namespaced do
      transient do
        hostname { "raw.#{Faker::Internet.domain_name}" }
        entity_id_uri { "https://#{hostname}/shibboleth" }
        namespace { 'xyz:' }
        disco_hints do
          <<~ENTITY.strip
            <mdui:DiscoHints>
              <mdui:IPHint>2001:620::0/96</mdui:IPHint>
              <mdui:DomainHint>example.edu</mdui:DomainHint>
              <mdui:GeolocationHint>
                geo:47.37328,8.531126
              </mdui:GeolocationHint>
              <mdui:GeolocationHint>
                http://invalid.example.com
              </mdui:GeolocationHint>
            </mdui:DiscoHints>
          ENTITY
        end
      end

      enabled { true }

      association :known_entity
    end
  end
end

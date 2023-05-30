# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetSamlTypeFromXml do
  let(:known_entity) { spy(KnownEntity) }
  let(:red) { spy(RawEntityDescriptor, known_entity:) }
  let(:ed_node) { double(Nokogiri::XML::Node) }
  let(:klass) { Class.new { include SetSamlTypeFromXml } }
  let(:absent_role_descriptor) { nil }
  let(:present_role_descriptor) { double(present?: true) }
  let(:idp_sso_descriptor) { absent_role_descriptor }
  let(:attribute_authority_descriptor) { absent_role_descriptor }
  let(:sp_sso_descriptor) { absent_role_descriptor }
  let(:entity_attributes) { {} }

  def attribute_value(value)
    double(Nokogiri::XML::Node, text: value)
  end

  let(:sirtfi) do
    {
      'urn:oasis:names:tc:SAML:attribute:assurance-certification' =>
      [attribute_value('https://refeds.org/sirtfi')]
    }
  end

  let(:sirtfi_v2) do
    {
      'urn:oasis:names:tc:SAML:attribute:assurance-certification' =>
      [attribute_value('https://refeds.org/sirtfi2')]
    }
  end

  let(:supports_research_scholarship) do
    {
      'http://macedir.org/entity-category-support' =>
      [attribute_value('http://refeds.org/category/research-and-scholarship')]
    }
  end

  let(:conforms_to_research_scholarship) do
    {
      'http://macedir.org/entity-category' =>
      [attribute_value('http://refeds.org/category/research-and-scholarship')]
    }
  end

  let(:supports_dp_coco) do
    {
      'http://macedir.org/entity-category-support' =>
      [attribute_value('http://www.geant.net/uri/dataprotection-code-of-conduct/v1')]
    }
  end

  let(:conforms_to_dp_coco) do
    {
      'http://macedir.org/entity-category' =>
      [attribute_value('http://www.geant.net/uri/dataprotection-code-of-conduct/v1')]
    }
  end

  let(:supports_refeds_coco_v2) do
    {
      'http://macedir.org/entity-category-support' =>
      [attribute_value('https://refeds.org/category/code-of-conduct/v2')]
    }
  end

  let(:conforms_to_refeds_coco_v2) do
    {
      'http://macedir.org/entity-category' =>
      [attribute_value('https://refeds.org/category/code-of-conduct/v2')]
    }
  end

  let(:requests_hide_from_discovery) do
    {
      'http://macedir.org/entity-category' =>
      [attribute_value('http://refeds.org/category/hide-from-discovery')]
    }
  end

  let(:requests_refeds_anonymous_access) do
    {
      'http://macedir.org/entity-category' =>
      [attribute_value('https://refeds.org/category/anonymous')]
    }
  end

  let(:supports_refeds_anonymous_access) do
    {
      'http://macedir.org/entity-category-support' =>
      [attribute_value('https://refeds.org/category/anonymous')]
    }
  end

  let(:requests_refeds_pseudonymous_access) do
    {
      'http://macedir.org/entity-category' =>
      [attribute_value('https://refeds.org/category/pseudonymous')]
    }
  end

  let(:supports_refeds_pseudonymous_access) do
    {
      'http://macedir.org/entity-category-support' =>
      [attribute_value('https://refeds.org/category/pseudonymous')]
    }
  end

  let(:requests_refeds_personalized_access) do
    {
      'http://macedir.org/entity-category' =>
      [attribute_value('https://refeds.org/category/personalized')]
    }
  end

  let(:supports_refeds_personalized_access) do
    {
      'http://macedir.org/entity-category-support' =>
      [attribute_value('https://refeds.org/category/personalized')]
    }
  end

  let(:xpath_results) do
    {
      'IDPSSODescriptor' => idp_sso_descriptor,
      'AttributeAuthorityDescriptor' => attribute_authority_descriptor,
      'SPSSODescriptor' => sp_sso_descriptor
    }
  end

  subject { klass.new }

  before do
    allow(ed_node).to receive(:xpath) do |path|
      if path.match?(/EntityAttributes/)
        prefix = './/*[local-name() = "EntityAttributes" ' \
                 'and namespace-uri() = "urn:oasis:names:tc:SAML:metadata:attribute"]' \
                 '/*[local-name() = "Attribute" ' \
                 'and namespace-uri() = "urn:oasis:names:tc:SAML:2.0:assertion" ' \
                 'and @Name = "'

        suffix = '"]' \
                 '/*[local-name() = "AttributeValue" ' \
                 'and namespace-uri() = "urn:oasis:names:tc:SAML:2.0:assertion"]'

        getter = ->(v) { entity_attributes.fetch(v, []) }
      else
        prefix = '//*[local-name() = "'

        suffix = '" and namespace-uri() = ' \
                 '"urn:oasis:names:tc:SAML:2.0:metadata"]'

        getter = lambda do |v|
          expect(xpath_results).to have_key(v)
          xpath_results[v]
        end
      end

      pattern = "#{Regexp.escape(prefix)}(.+)#{Regexp.escape(suffix)}"
      match = Regexp.new(pattern).match(path)

      expect(match).to be_present
      getter.call(match[1])
    end
  end

  describe '.set_saml_type' do
    before { subject.set_saml_type(red, ed_node) }

    # Sanity check; the XML would be invalid anyway
    context 'with no type' do
      it 'removes the flags' do
        expect(red).to have_received(:update)
          .with(idp: false, sp: false, standalone_aa: false)
      end

      it 'removes the tags' do
        expect(known_entity).to have_received(:untag_as).with('idp')
        expect(known_entity).to have_received(:untag_as).with('aa')
        expect(known_entity).to have_received(:untag_as).with('sp')
        expect(known_entity).to have_received(:untag_as).with('standalone-aa')
        expect(known_entity).to have_received(:untag_as).with('sirtfi')
        expect(known_entity).to have_received(:untag_as).with('sirtfi-v2')
        expect(known_entity).to have_received(:untag_as)
          .with('research-and-scholarship')
        expect(known_entity).to have_received(:untag_as).with('dp-coco')
        expect(known_entity).to have_received(:untag_as).with('refeds-coco-v2')
        expect(known_entity).to have_received(:untag_as).with('hide-from-discovery')
        expect(known_entity).to have_received(:untag_as).with('anonymous-access')
        expect(known_entity).to have_received(:untag_as).with('pseudonymous-access')
        expect(known_entity).to have_received(:untag_as).with('personalized-access')
      end
    end

    context 'with an IDPSSODescriptor' do
      let(:idp_sso_descriptor) { present_role_descriptor }

      it 'sets the flags' do
        expect(red).to have_received(:update)
          .with(idp: true, sp: false, standalone_aa: false)
      end

      it 'adds the tag' do
        expect(known_entity).to have_received(:tag_as).with('idp')
      end

      it 'removes the other tags' do
        expect(known_entity).to have_received(:untag_as).with('aa')
        expect(known_entity).to have_received(:untag_as).with('sp')
        expect(known_entity).to have_received(:untag_as).with('standalone-aa')
      end

      context 'when SIRTFI is asserted' do
        let(:entity_attributes) { sirtfi }

        it 'adds the tag' do
          expect(known_entity).to have_received(:tag_as).with('sirtfi')
        end
      end

      context 'when SIRTFIv2 is asserted' do
        let(:entity_attributes) { sirtfi_v2 }

        it 'adds the tag' do
          expect(known_entity).to have_received(:tag_as).with('sirtfi-v2')
        end
      end

      context 'when R&S is supported' do
        let(:entity_attributes) { supports_research_scholarship }

        it 'adds the tag' do
          expect(known_entity).to have_received(:tag_as)
            .with('research-and-scholarship')
        end
      end

      context 'when DPCoCo is supported' do
        let(:entity_attributes) { supports_dp_coco }

        it 'adds the tag' do
          expect(known_entity).to have_received(:tag_as)
            .with('dp-coco')
        end
      end

      context 'when REFEDS CoCo V2 is supported' do
        let(:entity_attributes) { supports_refeds_coco_v2 }

        it 'adds the tag' do
          expect(known_entity).to have_received(:tag_as)
            .with('refeds-coco-v2')
        end
      end

      context 'when hide from discovery is requested' do
        let(:entity_attributes) { requests_hide_from_discovery }

        it 'adds the tag' do
          expect(known_entity).to have_received(:tag_as)
            .with('hide-from-discovery')
        end
      end

      context 'when REFEDS anonymous access is supported' do
        let(:entity_attributes) { supports_refeds_anonymous_access }

        it 'adds the tag' do
          expect(known_entity).to have_received(:tag_as)
            .with('anonymous-access')
        end
      end

      context 'when REFEDS pseudonymous access is supported' do
        let(:entity_attributes) { supports_refeds_pseudonymous_access }

        it 'adds the tag' do
          expect(known_entity).to have_received(:tag_as)
            .with('pseudonymous-access')
        end
      end

      context 'when REFEDS personalized access is supported' do
        let(:entity_attributes) { supports_refeds_personalized_access }

        it 'adds the tag' do
          expect(known_entity).to have_received(:tag_as)
            .with('personalized-access')
        end
      end
    end

    context 'with an SPSSODescriptor' do
      let(:sp_sso_descriptor) { present_role_descriptor }

      it 'sets the flags' do
        expect(red).to have_received(:update)
          .with(sp: true, idp: false, standalone_aa: false)
      end

      it 'adds the tag' do
        expect(known_entity).to have_received(:tag_as).with('sp')
      end

      it 'removes the other tags' do
        expect(known_entity).to have_received(:untag_as).with('idp')
        expect(known_entity).to have_received(:untag_as).with('aa')
        expect(known_entity).to have_received(:untag_as).with('standalone-aa')
      end

      context 'when SIRTFI is asserted' do
        let(:entity_attributes) { sirtfi }

        it 'adds the tag' do
          expect(known_entity).to have_received(:tag_as).with('sirtfi')
        end
      end

      context 'when SIRTFI V2 is asserted' do
        let(:entity_attributes) { sirtfi_v2 }

        it 'adds the tag' do
          expect(known_entity).to have_received(:tag_as).with('sirtfi-v2')
        end
      end

      context 'when conforming to R&S' do
        let(:entity_attributes) { conforms_to_research_scholarship }

        it 'adds the tag' do
          expect(known_entity).to have_received(:tag_as)
            .with('research-and-scholarship')
        end
      end

      context 'when conforming to DP-Coco' do
        let(:entity_attributes) { conforms_to_dp_coco }

        it 'adds the tag' do
          expect(known_entity).to have_received(:tag_as)
            .with('dp-coco')
        end
      end

      context 'when conforming to REFEDS CoCo V2' do
        let(:entity_attributes) { conforms_to_refeds_coco_v2 }

        it 'adds the tag' do
          expect(known_entity).to have_received(:tag_as)
            .with('refeds-coco-v2')
        end
      end

      context 'when requesting anonymous access' do
        let(:entity_attributes) { requests_refeds_anonymous_access }

        it 'adds the tag' do
          expect(known_entity).to have_received(:tag_as)
            .with('anonymous-access')
        end
      end

      context 'when requesting pseudonymous access' do
        let(:entity_attributes) { requests_refeds_pseudonymous_access }

        it 'adds the tag' do
          expect(known_entity).to have_received(:tag_as)
            .with('pseudonymous-access')
        end
      end

      context 'when requesting personalized access' do
        let(:entity_attributes) { requests_refeds_personalized_access }

        it 'adds the tag' do
          expect(known_entity).to have_received(:tag_as)
            .with('personalized-access')
        end
      end
    end

    context 'with an AttributeAuthorityDescriptor' do
      let(:attribute_authority_descriptor) { present_role_descriptor }

      it 'sets the flags' do
        expect(red).to have_received(:update)
          .with(sp: false, idp: false, standalone_aa: true)
      end

      it 'adds the tag' do
        expect(known_entity).to have_received(:tag_as).with('standalone-aa')
      end

      it 'removes the other tags' do
        expect(known_entity).to have_received(:untag_as).with('idp')
        expect(known_entity).to have_received(:untag_as).with('aa')
        expect(known_entity).to have_received(:untag_as).with('sp')
      end
    end

    context 'with an IDPSSODescriptor + AttributeAuthorityDescriptor' do
      let(:idp_sso_descriptor) { present_role_descriptor }
      let(:attribute_authority_descriptor) { present_role_descriptor }

      it 'sets the flags' do
        expect(red).to have_received(:update)
          .with(idp: true, sp: false, standalone_aa: false)
      end

      it 'adds the tags' do
        expect(known_entity).to have_received(:tag_as).with('idp')
        expect(known_entity).to have_received(:tag_as).with('aa')
      end

      it 'removes the other tags' do
        expect(known_entity).to have_received(:untag_as).with('sp')
        expect(known_entity).to have_received(:untag_as).with('standalone-aa')
      end
    end
  end
end

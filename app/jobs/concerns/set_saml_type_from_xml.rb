# frozen_string_literal: true

module SetSamlTypeFromXml
  def self.xpath_for_metadata_element(name)
    "//*[local-name() = \"#{name}\" and " \
      'namespace-uri() = "urn:oasis:names:tc:SAML:2.0:metadata"]'
  end

  ENTITY_DESCRIPTOR_XPATH = xpath_for_metadata_element('EntityDescriptor')
  IDP_SSO_DESCRIPTOR_XPATH = xpath_for_metadata_element('IDPSSODescriptor')
  SP_SSO_DESCRIPTOR_XPATH = xpath_for_metadata_element('SPSSODescriptor')
  ATTRIBUTE_AUTHORITY_DESCRIPTOR_XPATH =
    xpath_for_metadata_element('AttributeAuthorityDescriptor')
  RESEARCH_AND_SCHOLARSHIP_CATEGORY = 'http://refeds.org/category/research-and-scholarship'
  DP_COCO_CATEGORY = 'http://www.geant.net/uri/dataprotection-code-of-conduct/v1'
  ENTITY_CATEGORY_ATTR = 'http://macedir.org/entity-category'
  ENTITY_CATEGORY_SUPPORT_ATTR = 'http://macedir.org/entity-category-support'

  def self.xpath_for_entity_attribute_values(name)
    './/*[local-name() = "EntityAttributes" ' \
      'and namespace-uri() = "urn:oasis:names:tc:SAML:metadata:attribute"]' \
      '/*[local-name() = "Attribute" ' \
      'and namespace-uri() = "urn:oasis:names:tc:SAML:2.0:assertion" ' \
      "and @Name = \"#{name}\"]" \
      '/*[local-name() = "AttributeValue" ' \
      'and namespace-uri() = "urn:oasis:names:tc:SAML:2.0:assertion"]'
  end

  private_constant :ENTITY_DESCRIPTOR_XPATH, :IDP_SSO_DESCRIPTOR_XPATH,
                   :ATTRIBUTE_AUTHORITY_DESCRIPTOR_XPATH,
                   :SP_SSO_DESCRIPTOR_XPATH

  def set_saml_type(red, ed_node)
    tags = desired_entity_tags(ed_node) + desired_entity_category_tags(ed_node)
    untags = all_entity_tags - tags

    red.update(idp: tags.include?(Tag::IDP),
               sp: tags.include?(Tag::SP),
               standalone_aa: tags.include?(Tag::STANDALONE_AA))

    ke = red.known_entity
    tags.each { |tag| ke.tag_as(tag) }
    untags.each { |tag| ke.untag_as(tag) }
  end

  def desired_entity_tags(ed_node)
    tags = []

    if entity_has_idp_role?(ed_node)
      tags << Tag::IDP
      tags << Tag::AA if entity_has_aa_role?(ed_node)
    elsif entity_has_aa_role?(ed_node)
      tags << Tag::STANDALONE_AA
    end

    tags << Tag::SP if entity_has_sp_role?(ed_node)

    tags
  end

  def desired_entity_category_tags(ed_node)
    tags = []
    tags << Tag::RESEARCH_SCHOLARSHIP if research_scholarship_entity?(ed_node)
    tags << Tag::DP_COCO if dp_coco_entity?(ed_node)
    tags << Tag::SIRTFI if sirtfi_entity?(ed_node)
    tags
  end

  def all_entity_tags
    [Tag::IDP, Tag::AA, Tag::STANDALONE_AA, Tag::SP,
     Tag::RESEARCH_SCHOLARSHIP, Tag::DP_COCO, Tag::SIRTFI]
  end

  def entity_has_idp_role?(ed_node)
    ed_node.xpath(IDP_SSO_DESCRIPTOR_XPATH).present?
  end

  def entity_has_aa_role?(ed_node)
    ed_node.xpath(ATTRIBUTE_AUTHORITY_DESCRIPTOR_XPATH).present?
  end

  def entity_has_sp_role?(ed_node)
    ed_node.xpath(SP_SSO_DESCRIPTOR_XPATH).present?
  end

  def matches_entity_attribute_value?(ed_node, name, value)
    xpath = SetSamlTypeFromXml.xpath_for_entity_attribute_values(name)
    ed_node.xpath(xpath).any? { |n| n.text == value }
  end

  def research_scholarship_entity?(ed_node)
    sp_has_category?(ed_node, RESEARCH_AND_SCHOLARSHIP_CATEGORY) ||
      idp_supports_category?(ed_node, RESEARCH_AND_SCHOLARSHIP_CATEGORY)
  end

  def dp_coco_entity?(ed_node)
    sp_has_category?(ed_node, DP_COCO_CATEGORY) ||
      idp_supports_category?(ed_node, DP_COCO_CATEGORY)
  end

  def sp_has_category?(ed_node, category)
    return false unless entity_has_sp_role?(ed_node)

    matches_entity_attribute_value?(
      ed_node, ENTITY_CATEGORY_ATTR, category
    )
  end

  def idp_supports_category?(ed_node, category)
    return false unless entity_has_idp_role?(ed_node)

    matches_entity_attribute_value?(
      ed_node, ENTITY_CATEGORY_SUPPORT_ATTR, category
    )
  end

  def sirtfi_entity?(ed_node)
    matches_entity_attribute_value?(
      ed_node,
      'urn:oasis:names:tc:SAML:attribute:assurance-certification',
      'https://refeds.org/sirtfi'
    )
  end
end

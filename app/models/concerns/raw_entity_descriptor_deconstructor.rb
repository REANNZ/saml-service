# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module RawEntityDescriptorDeconstructor
  extend ActiveSupport::Concern
  def ui_info
    ui_info_node = Nokogiri::XML.parse(xml).xpath(UI_INFO_PATH)
    return if ui_info_node.blank?

    ui_info = os(display_names: [], descriptions: [], logos: [],
                 information_urls: [], privacy_statement_urls: [])

    display_names(ui_info_node, ui_info)
    descriptions(ui_info_node, ui_info)
    logos(ui_info_node, ui_info)
    information_urls(ui_info_node, ui_info)
    privacy_statement_urls(ui_info_node, ui_info)

    ui_info
  end

  def disco_hints
    doc = Nokogiri::XML.parse(xml)
    disco_hints_node = doc.xpath(DISCO_HINTS_PATH)
    return if disco_hints_node.blank?

    disco_hints = os(ip_hints: [], domain_hints: [], geolocation_hints: [])

    ip_hints(disco_hints_node, disco_hints)
    domain_hints(disco_hints_node, disco_hints)
    geolocation_hints(disco_hints_node, disco_hints)

    disco_hints
  end

  def discovery_response_services
    doc = Nokogiri::XML.parse(xml)
    discovery_response_node = doc.xpath(DISCOVERY_RESPONSE_PATH)
    return if discovery_response_node.blank?

    extract_discovery_response_services(discovery_response_node)
  end

  def single_sign_on_services
    doc = Nokogiri::XML.parse(xml)
    single_sign_on_services_node = doc.xpath(SINGLE_SIGN_ON_SERVICE_PATH)
    return if single_sign_on_services_node.blank?

    extract_single_sign_on_services(single_sign_on_services_node)
  end

  def display_names(ui_info_node, ui_info)
    ui_info_node.xpath(UI_INFO_DISPLAY_NAME_PATH).each do |dn|
      ui_info.display_names <<
        os(lang: dn.attributes['lang'].value, value: dn.text.strip)
    end
  end

  def descriptions(ui_info_node, ui_info)
    ui_info_node.xpath(UI_INFO_DESCRIPTION_PATH).each do |desc|
      ui_info.descriptions <<
        os(lang: desc.attributes['lang'].value, value: desc.text.strip)
    end
  end

  def logos(ui_info_node, ui_info)
    ui_info_node.xpath(UI_INFO_LOGO_PATH).each do |logo|
      ui_info.logos <<
        os(width: logo.attributes['width'].value,
           height: logo.attributes['height'].value,
           uri: logo.text.strip)
    end
  end

  def information_urls(ui_info_node, ui_info)
    ui_info_node.xpath(UI_INFO_INFORMATION_URL_PATH).each do |inf|
      ui_info.information_urls <<
        os(lang: inf.attributes['lang'].value, uri: inf.text.strip)
    end
  end

  def privacy_statement_urls(ui_info_node, ui_info)
    ui_info_node.xpath(UI_INFO_PRIVACY_STATEMENT_URL_PATH).each do |ps|
      ui_info.privacy_statement_urls <<
        os(lang: ps.attributes['lang'].value, uri: ps.text.strip)
    end
  end

  def ip_hints(disco_hints_node, disco_hints)
    disco_hints_node.xpath(DISCO_HINTS_IP_HINT_PATH).each do |iph|
      disco_hints.ip_hints <<
        os(block: iph.text.strip)
    end
  end

  def domain_hints(disco_hints_node, disco_hints)
    disco_hints_node.xpath(DISCO_HINTS_DOMAIN_HINT_PATH).each do |dh|
      disco_hints.domain_hints <<
        os(domain: dh.text.strip)
    end
  end

  def geolocation_hints(disco_hints_node, disco_hints)
    disco_hints_node.xpath(DISCO_HINTS_GEOLOCATION_HINT_PATH).each do |glh|
      uri = glh.text.strip
      next unless valid_geolocation_uri?(uri)

      uri_parts = MDUI::GeolocationHint.parse_uri_into_parts(uri)
      disco_hints.geolocation_hints <<
        os(latitude: uri_parts[0], longitude: uri_parts[1],
           altitude: uri_parts[2])
    end
  end

  def valid_geolocation_uri?(uri)
    MDUI::GeolocationHint.valid_uri?(uri)
  end

  # rubocop:disable Metrics/MethodLength

  def extract_discovery_response_services(discovery_response_node)
    discovery_response_node.map do |ds|
      os(
        location: ds.attributes['Location'].value,
        binding: ds.attributes['Binding'].value,
        index: ds.attributes['index'].value.to_i,
        is_default: case ds.attributes['isDefault'].try(:value)
                    when 'true'
                      true
                    when 'false'
                      false
                    end
      )
    end
  end
  # rubocop:enable Metrics/MethodLength

  def extract_single_sign_on_services(single_sign_on_services_node)
    single_sign_on_services_node.map do |sso|
      os(
        location: sso.attributes['Location'].value,
        binding: sso.attributes['Binding'].value
      )
    end
  end

  private

  # rubocop:disable Style/OpenStructUse
  def os(hash)
    OpenStruct.new(hash)
  end
  # rubocop:enable Style/OpenStructUse

  class << self
    private

    def element_xpath(uri, name)
      %(.//*[local-name() = "#{name}" and namespace-uri() = "#{uri}"])
    end

    def mdui_element_xpath(name)
      element_xpath('urn:oasis:names:tc:SAML:metadata:ui', name)
    end

    def idpdisc_element_xpath(name)
      uri = 'urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol'
      element_xpath(uri, name)
    end

    def saml_element_xpath(name)
      uri = 'urn:oasis:names:tc:SAML:2.0:metadata'
      element_xpath(uri, name)
    end
  end

  UI_INFO_PATH = mdui_element_xpath('UIInfo')
  UI_INFO_DISPLAY_NAME_PATH = mdui_element_xpath('DisplayName')
  UI_INFO_DESCRIPTION_PATH = mdui_element_xpath('Description')
  UI_INFO_LOGO_PATH = mdui_element_xpath('Logo')
  UI_INFO_INFORMATION_URL_PATH = mdui_element_xpath('InformationURL')
  UI_INFO_PRIVACY_STATEMENT_URL_PATH = mdui_element_xpath('PrivacyStatementURL')
  DISCO_HINTS_PATH = mdui_element_xpath('DiscoHints')
  DISCO_HINTS_IP_HINT_PATH = mdui_element_xpath('IPHint')
  DISCO_HINTS_DOMAIN_HINT_PATH = mdui_element_xpath('DomainHint')
  DISCO_HINTS_GEOLOCATION_HINT_PATH = mdui_element_xpath('GeolocationHint')
  DISCOVERY_RESPONSE_PATH = idpdisc_element_xpath('DiscoveryResponse')
  SINGLE_SIGN_ON_SERVICE_PATH = saml_element_xpath('SingleSignOnService')

  private_constant :UI_INFO_PATH, :UI_INFO_DISPLAY_NAME_PATH,
                   :UI_INFO_DESCRIPTION_PATH, :UI_INFO_LOGO_PATH,
                   :UI_INFO_INFORMATION_URL_PATH,
                   :UI_INFO_PRIVACY_STATEMENT_URL_PATH, :DISCO_HINTS_PATH,
                   :DISCO_HINTS_IP_HINT_PATH, :DISCO_HINTS_DOMAIN_HINT_PATH,
                   :DISCO_HINTS_GEOLOCATION_HINT_PATH, :DISCOVERY_RESPONSE_PATH,
                   :SINGLE_SIGN_ON_SERVICE_PATH
end
# rubocop:enable Metrics/ModuleLength

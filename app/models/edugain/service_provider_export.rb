# frozen_string_literal: true

module Edugain
  class ServiceProviderExport < AbstractEntityExport
    attr_reader :information_url

    def initialize(entity_id:, information_url:)
      super(entity_id:)
      @information_url = information_url
    end

    def save
      add_info_url
      super
    end

    private

    def research_and_scholarship_attribute_name
      'http://macedir.org/entity-category'
    end

    def add_info_url
      entity_descriptor.sp_sso_descriptors.each do |descriptor|
        ui_info = descriptor.ui_info || raise('no UIInfo, should not be possible')
        next if ui_info.information_urls.any?

        MDUI::InformationURL.create ui_info:, uri: information_url, lang: 'en'
      end
    end
  end
end

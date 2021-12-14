# frozen_string_literal: true

module EdugainHelper
    DEFAULT_EDUGAIN_EXPORT_TAG_NAME = 'aaf-edugain-export'
    DEFAULT_EDUGAIN_VERIFIED_TAG_NAME = 'aaf-edugain-verified'

    def EdugainHelper.edugain_export_tag
      Rails.application.config.saml_service&.api&.edugain_export_tag_name ||
        DEFAULT_EDUGAIN_EXPORT_TAG_NAME
    end

    def EdugainHelper.edugain_verified_tag
      Rails.application.config.saml_service&.api&.edugain_verified_tag_name ||
        DEFAULT_EDUGAIN_VERIFIED_TAG_NAME
    end
end

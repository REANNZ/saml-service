# frozen_string_literal: true

class HealthController < ApplicationController
  skip_before_action :ensure_authenticated
  skip_after_action :ensure_access_checked

  def show
    redis_url = Rails.application.config.saml_service[:redis][:url]
    (Rails.env.production? && Redis.new(
      url: redis_url,
      ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
    ).ping) && Sequel::Model.db.test_connection
  end
end

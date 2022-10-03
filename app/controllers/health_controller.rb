# frozen_string_literal: true

class HealthController < ApplicationController
  skip_before_action :ensure_authenticated
  skip_after_action :ensure_access_checked

  def show
    render json: {
      version: Rails.application.config.saml_service[:version],
      redis_active: redis_active?,
      db_active: Sequel::Model.db.test_connection
    }
  end

  private

  def redis_active?
    (Rails.env.production? && Redis.new(
      url: Rails.application.config.saml_service[:redis][:url],
      ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
    ).ping)
  end
end

# frozen_string_literal: true

class HealthController < ApplicationController
  def self.redis
    Redis.new(
      url: Rails.application.config.saml_service[:redis][:url],
      ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
    )
  end

  def show
    redis_active = redis_active?
    db_active = db_active?

    render json: {
      version: Rails.application.config.saml_service[:version],
      redis_active: redis_active,
      db_active: db_active
    }, status: db_active && redis_active ? 200 : 503
  end

  private

  def redis_active?
    # :nocov:
    HealthController.redis&.ping && true
    # :nocov:
  rescue StandardError
    false
  end

  def db_active?
    Sequel::Model.db.test_connection
  rescue StandardError
    false
  end
end

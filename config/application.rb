# frozen_string_literal: true

require File.expand_path('boot', __dir__)

# Pick the frameworks you want:
require 'active_model/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
# require 'sprockets/railtie'
# require 'active_record/railtie'
# require 'rails/test_unit/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

Sequel.default_timezone = :utc

module Saml
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those
    # specified here.
    redis_user = ''
    redis_user = ":#{CGI.escape(ENV.fetch('REDIS_AUTH_TOKEN', nil))}@" if ENV.fetch('REDIS_AUTH_TOKEN', nil).present?
    config.saml_service =
      RecursiveOpenStruct.new({
        metadata: {
          negative_cache_ttl: 600
        },
        api: {
          authentication: :token,
          edugain_export_tag_name: ENV.fetch('API_EDUGAIN_EXPORT_TAG_NAME', 'aaf-edugain-export'),
          edugain_verified_tag_name: ENV.fetch('API_EDUGAIN_VERIFIED_TAG_NAME', 'aaf-edugain-verified')
        },
        url_options: {
          base_url: ENV.fetch('BASE_URL', nil)
        },
        redis: {
          namespace: ENV.fetch('REDIS_NAMESPACE', '_saml'),
          url: "#{ENV.fetch('REDIS_SCHEME', 'redis')}://#{redis_user}#{ENV.fetch('REDIS_HOST', 'localhost')}:6379/0"
        },
        version: "#{ENV.fetch('RELEASE_VERSION', 'OWO')}-#{ENV.fetch('SERIAL_NUMBER', 1)}"
      }.deep_symbolize_keys)

    config.load_defaults 6.0
    config.autoloader = :zeitwerk

    config.sequel.after_connect = proc do
      Sequel::Model.db.extension :connection_validator
      Sequel::Model.db.pool.connection_validation_timeout = -1
      Sequel::Model.plugin :timestamps, update_on_create: true
      Sequel::Model.plugin :validation_helpers
    end

    config.autoload_paths << Rails.root.join('app', 'jobs', 'concerns')

    config.sequel.logger = Logger.new($stderr) if ENV['AAF_DEBUG']

    config.force_ssl
  end
end

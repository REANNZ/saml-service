# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require 'spec_helper'
require 'factory_bot_rails'
require File.expand_path('../config/environment', __dir__)
require 'rspec/rails'
require 'capybara/rails'

Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each do |f|
  require f
end

Timecop.safe_mode = true

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.include FactoryBot::Syntax::Methods
  config.include Rails.application.routes.url_helpers

  # Use Sequel matchers and transactions
  config.include RspecSequel::Matchers
  config.around(:each) do |spec|
    Sequel::Model.db.transaction(rollback: :always,
                                 auto_savepoint: true) { spec.run }
  end

  config.around(:each, :debug) do |spec|
    logger = Logger.new($stderr)
    Sequel::Model.db.loggers << logger
    spec.run
  ensure
    Sequel::Model.db.loggers.delete(logger)
  end

  config.infer_spec_type_from_file_location!
end

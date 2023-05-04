# frozen_string_literal: true

require 'simplecov'
require 'webmock/rspec'
require 'fakeredis/rspec'
require 'simplecov-console'

SimpleCov.formatter = SimpleCov::Formatter::Console

RSpec.configure do |config|
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.order = :random
  Kernel.srand config.seed

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.syntax = :expect
    mocks.verify_partial_doubles = true
  end
  config.after(:each) do
    Rails.cache.clear
  end
  config.after(:suite) do
    WebMock.disable_net_connect!
  end

  config.alias_it_should_behave_like_to :has_behavior, 'has behavior:'

  RSpec::Matchers.define_negated_matcher :not_include, :include
  RSpec::Matchers.define_negated_matcher :not_change, :change
end

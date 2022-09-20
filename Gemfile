# frozen_string_literal: true

source 'https://rubygems.org'

gem 'rails', '<7'

gem 'accession'
gem 'mysql2'
gem 'sequel', '>= 4.0.0', '< 5'
gem 'sequel-rails'

gem 'nokogiri', '>= 1.8.5'
gem 'xmldsig'

gem 'redis'
gem 'redis-rails'
gem 'resque'
gem 'resque-retry'

gem 'implicit-schema'

gem 'recursive-open-struct'

gem 'jbuilder'

gem 'bcrypt', '~> 3.1'

gem 'rugged', '0.28.4.1', require: false

gem 'puma', require: false

group :development, :test do
  gem 'capybara'
  gem 'rspec-rails'
  gem 'rspec-retry'
  gem 'webmock', require: false

  gem 'aaf-gumboot'
  gem 'factory_bot_rails', '~> 4.11' # TODO: Upgrade to v5 in the furture.
  gem 'faker'
  gem 'rails-controller-testing'
  gem 'rspec_sequel_matchers', '~> 0.5.0'
  gem 'shoulda-matchers'

  gem 'fakeredis', require: false
  gem 'simplecov', require: false
  gem 'timecop'

  gem 'guard', require: false
  gem 'guard-brakeman', require: false
  gem 'guard-bundler', require: false
  gem 'guard-rspec', require: false
  gem 'guard-rubocop', '1.3.0', require: false
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rubocop', '0.85.1', require: false
  gem 'rubocop-ast', '0.0.3', require: false
  gem 'rubocop-faker', '1.0.0', require: false
  gem 'rubocop-rails', '2.6.0', require: false
end

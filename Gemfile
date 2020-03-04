# frozen_string_literal: true

source 'https://rubygems.org'

gem 'rails', '>= 5', '< 6'

gem 'accession'
gem 'mysql2'
gem 'sequel', '>= 4.0.0', '< 5'
gem 'sequel-rails'
gem 'sprockets', '3.7.2'

gem 'nokogiri', '>= 1.8.5'
gem 'xmldsig'

gem 'redis'
gem 'redis-rails'
gem 'resque'
gem 'resque-retry'

gem 'implicit-schema'

gem 'recursive-open-struct'

gem 'therubyracer', platforms: :ruby
gem 'uglifier', '>= 1.3.0'

gem 'jbuilder'

gem 'bcrypt', '~> 3.1'

gem 'rugged', require: false

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
  gem 'rspec_sequel_matchers', git: 'https://github.com/bradleybeddoes/rspec_sequel_matchers.git'
  gem 'shoulda-matchers'

  gem 'codeclimate-test-reporter', require: false
  gem 'fakeredis', require: false
  gem 'simplecov', require: false
  gem 'timecop'

  gem 'guard', require: false
  gem 'guard-brakeman', require: false
  gem 'guard-bundler', require: false
  gem 'guard-rspec', require: false
  gem 'guard-rubocop', require: false
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rubocop', require: false
  gem 'rubocop-faker', require: false
  gem 'rubocop-rails', require: false
end

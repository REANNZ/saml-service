# frozen_string_literal: true

require File.expand_path('config/application', __dir__)

Rails.application.load_tasks

begin
  require 'rubocop/rake_task'
  require 'brakeman'

  RuboCop::RakeTask.new

  task brakeman: :environment do
    result = Brakeman.run app_path: '.', print_report: true, pager: false

    unless result.filtered_warnings.empty?
      puts "Brakeman found #{result.filtered_warnings.count} warnings"
      exit 1
    end
  end

  task default: %i[rubocop spec brakeman]
rescue LoadError
  task default: []
end

task spec: :'xsd:all'

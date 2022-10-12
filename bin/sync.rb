#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../config/environment'

class SyncCLI
  def self.perform(source_tag)
    entity_source = EntitySource[source_tag: source_tag]
    raise("The source_tag #{source_tag} is invalid") unless entity_source

    if entity_source.url
      UpdateEntitySource.perform(id: entity_source.id)
    else
      fr_source = FederationRegistrySource[entity_source: entity_source]
      UpdateFromFederationRegistry.perform(id: fr_source.id)
    end
  end
end

# :nocov:
if $PROGRAM_NAME == __FILE__
  begin
    SyncCLI.perform(*ARGV)
  rescue StandardError => e
    Sentry.capture_exception(e)
    raise e
  end
end
# :nocov:

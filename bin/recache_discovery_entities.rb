#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../config/environment'
require 'discovery_entities'

class RecacheDiscoveryEntities
  def self.perform
    API::DiscoveryEntities.new.generate_cached_json(reset_cache: true)
  end
end

# :nocov:
if $PROGRAM_NAME == __FILE__
  begin
    RecacheDiscoveryEntities.perform
  rescue StandardError => e
    Sentry.capture_exception(e)
    raise e
  end
end
# :nocov:

# frozen_string_literal: true

require 'discovery_entities'
module API
  class DiscoveryEntitiesController < APIController
    skip_before_action :ensure_authenticated

    def index
      public_action
      render json: API::DiscoveryEntities.new.generate_cached_json
    end
  end
end

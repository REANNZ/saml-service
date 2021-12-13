# frozen_string_literal: true

module API
  module Edugain
    class ServiceProviderExportsController < APIController
      def create
        check_access! 'edugain:exports:create'
        Sequel::Model.db.transaction(isolation: :repeatable) do
          ::Edugain::ServiceProviderExport.new(
            entity_id: params.require(:entity_id),
            information_url: params.require(:information_url)
          ).save
        end
        head :no_content
      end
    end
  end
end

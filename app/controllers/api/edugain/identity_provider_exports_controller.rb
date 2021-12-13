# frozen_string_literal: true

module API
  module Edugain
    class IdentityProviderExportsController < APIController
      def create
        check_access! 'edugain:exports:create'
        Sequel::Model.db.transaction(isolation: :repeatable) do
          ::Edugain::IdentityProviderExport.new(entity_id: params.require(:entity_id)).save
        end
        head :no_content
      end
    end
  end
end

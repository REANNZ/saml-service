# frozen_string_literal: true

module API
  module Edugain
    class NonResearchAndScholarshipEntityApprovalsController < APIController
      def create
        check_access! 'edugain:imports:create'
        Sequel::Model.db.transaction(isolation: :repeatable) do
          ::Edugain::NonResearchAndScholarshipEntity.new(id: params.require(:entity_id)).approve
        end
        head :no_content
      end
    end
  end
end

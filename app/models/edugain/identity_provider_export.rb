# frozen_string_literal: true

module Edugain
  class IdentityProviderExport < AbstractEntityExport
    private

    def research_and_scholarship_attribute_name
      'http://macedir.org/entity-category-support'
    end
  end
end

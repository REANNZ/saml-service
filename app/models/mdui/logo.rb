# frozen_string_literal: true

module MDUI
  class Logo < Sequel::Model
    many_to_one :ui_info

    def validate
      super
      uri_regexp = URI::DEFAULT_PARSER.make_regexp(%w[http https])
      validates_presence %i[ui_info uri width height
                            created_at updated_at]
      validates_format uri_regexp, :uri

      validate_width
      validate_height
    end

    private

    def validate_width
      errors.add(:width, 'must specify pixels') unless width&.positive?
    end

    def validate_height
      errors.add(:height, 'must specify pixels') unless height&.positive?
    end
  end
end

# frozen_string_literal: true

class Endpoint < Sequel::Model
  plugin :class_table_inheritance

  def validate
    super
    uri_regexp = URI::DEFAULT_PARSER.make_regexp(%w[http https])
    validates_presence %i[binding location created_at updated_at]
    validates_format uri_regexp, :location
    validates_format uri_regexp, :response_location, allow_nil: true
  end

  def response_location?
    response_location.present?
  end
end

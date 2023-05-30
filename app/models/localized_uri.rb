# frozen_string_literal: true

class LocalizedURI < Sequel::Model
  plugin :class_table_inheritance, ignore_subclass_columns: %i[created_at updated_at]

  def validate
    super
    uri_regexp = URI::DEFAULT_PARSER.make_regexp(/(http|https)/i)
    validates_presence %i[uri lang created_at updated_at]
    validates_format uri_regexp, :uri
  end
end

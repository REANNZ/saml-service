# frozen_string_literal: true

class Tag < Sequel::Model
  URL_SAFE_BASE_64_ALPHABET = /^[a-zA-Z0-9_-]+$/.freeze

  include Parents
  plugin :validation_helpers
  many_to_one :known_entity

  alias derived? derived

  def validate
    super
    validates_unique(%i[name known_entity])
    validates_presence %i[known_entity name created_at updated_at]
    validates_format(URL_SAFE_BASE_64_ALPHABET,
                     :name, message: 'is not in base64 urlsafe alphabet')
  end

  IDP = 'idp'
  AA = 'aa'
  STANDALONE_AA = 'standalone-aa'
  SP = 'sp'
  RESEARCH_SCHOLARSHIP = 'research-and-scholarship'
  DP_COCO = 'dp-coco'
  SIRTFI = 'sirtfi'
  BLACKLIST = 'blacklist'
end

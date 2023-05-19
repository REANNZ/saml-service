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
  REFEDS_COCO_V2 = 'refeds-coco-v2'
  SIRTFI = 'sirtfi'
  SIRTFI_V2 = 'sirtfi-v2'
  HIDE_FROM_DISCOVERY = 'hide-from-discovery'
  ANONYMOUS_ACCESS = 'anonymous-access'
  PSEUDONYMOUS_ACCESS = 'pseudonymous-access'
  PERSONALIZED_ACCESS = 'personalized-access'
  BLACKLIST = 'blacklist'
end

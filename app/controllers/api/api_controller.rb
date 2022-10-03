# frozen_string_literal: true

require 'openssl'

module API
  class APIController < ActionController::API
    Forbidden = Class.new(StandardError)
    private_constant :Forbidden
    rescue_from Forbidden, with: :forbidden

    Unauthorized = Class.new(StandardError)
    private_constant :Unauthorized
    rescue_from Unauthorized, with: :unauthorized

    ResourceNotFound = Class.new(StandardError)
    rescue_from ResourceNotFound, Sequel::NoMatchingRow, with: :resource_not_found

    BadRequest = Class.new(StandardError)
    rescue_from BadRequest, with: :bad_request

    before_action :ensure_authenticated
    after_action :ensure_access_checked

    attr_reader :subject

    protected

    def ensure_authenticated
      if Rails.application.config.saml_service.api&.authentication.blank?
        raise(Forbidden, 'API authentication method is not configured')
      end

      authenticate

      raise(Unauthorized, 'Subject invalid') unless @subject
      raise(Unauthorized, 'Subject not functional') unless @subject.functioning?
    end

    def ensure_access_checked
      return if @access_checked

      method = "#{self.class.name}##{params[:action]}"
      raise("No access control performed by #{method}")
    end

    def authenticate
      if Rails.application.config.saml_service.api.authentication == :x509
        try_x509_authentication
      elsif Rails.application.config.saml_service.api.authentication == :token
        try_token_authentication
      else
        raise(Forbidden, 'A valid API authentication method is not configured')
      end
    end

    def try_x509_authentication
      raise(Unauthorized, 'x509 API authentication method not provided') if x509_dn.blank?

      @subject = APISubject[x509_cn: x509_cn]
    end

    def x509_cn
      x509_dn_parsed = OpenSSL::X509::Name.parse(x509_dn)
      x509_dn_hash = x509_dn_parsed.to_a
                                   .map { |components| components[0..1] }.to_h

      x509_dn_hash['CN'] || raise(Unauthorized, 'Subject CN invalid')
    rescue OpenSSL::X509::NameError
      raise(Unauthorized, 'Subject DN invalid')
    end

    def x509_dn
      x509_dn = request.headers['HTTP_X509_DN'].try(:force_encoding, 'UTF-8')
      x509_dn == '(null)' ? nil : x509_dn
    end

    def try_token_authentication
      header = request.headers['Authorization'].try(:force_encoding, 'UTF-8')
      raise(Unauthorized, 'Token API authentication method not provided') if header.blank?

      @subject = APISubject[token: bearer_token(header)]
    end

    def bearer_token(header)
      pattern = /^Bearer (?<token>\S+)/
      return $LAST_MATCH_INFO[:token] if header =~ pattern

      raise(Unauthorized, 'Invalid Authorization header value')
    end

    def check_access!(action)
      raise(Forbidden) unless @subject.permits?(action)

      @access_checked = true
    end

    def public_action
      @access_checked = true
    end

    def unauthorized(exception)
      message = 'Client request failure.'
      error = exception.message
      render json: { message: message, error: error }, status: :unauthorized
    end

    def forbidden(_exception)
      message = 'The request was understood but explicitly denied.'
      render json: { message: message }, status: :forbidden
    end

    def resource_not_found(_exception)
      message = 'Resource not found.'
      render json: { message: message }, status: :not_found
    end

    def bad_request(_exception)
      message = 'Bad request.'
      render json: { message: message }, status: :bad_request
    end
  end
end

# frozen_string_literal: true

module Coinbase
  module Wallet

    CLIENT_ERRORS = {
      400 => 'BadRequestError',
      401 => 'AuthenticationError',
      402 => 'TwoFactorRequiredError',
      403 => 'InvalidScopeError',
      404 => 'NotFoundError',
      422 => 'ValidationError',
      429 => 'RateLimitError',
      500 => 'InternalServerError',
      503 => 'ServiceUnavailableError',
      'param_required' => 'ParamRequiredError',
      'invalid_request' => 'InvalidRequestError',
      'personal_details_required' => 'PersonalDetailsRequiredError',
      'authentication_error' => 'AuthenticationError',
      'unverified_email' => 'UnverifiedEmailError',
      'invalid_token' => 'InvalidTokenError',
      'revoked_token' => 'RevokedTokenError',
      'expired_token' => 'ExpiredTokenError'
    }

    SERVER_ERRORS = {
      500 => 'InternalServerError',
      503 => 'ServiceUnavailableError'
    }

    #
    # Rest API Errors
    #
    class APIError < RuntimeError; end

    class ClientError < APIError; end

    class ServerError < APIError; end

    # Status 400
    class BadRequestError < ClientError; end

    class ParamRequiredError < ClientError; end

    class InvalidRequestError < ClientError; end

    class PersonalDetailsRequiredError < ClientError; end

    # Status 401
    class AuthenticationError < ClientError; end

    class UnverifiedEmailError < ClientError; end

    class InvalidTokenError < ClientError; end

    class RevokedTokenError < ClientError; end

    class ExpiredTokenError < ClientError; end

    # Status 402
    class TwoFactorRequiredError < ClientError; end

    # Status 403
    class InvalidScopeError < ClientError; end

    # Status 404
    class NotFoundError < ClientError; end

    # Status 422
    class ValidationError < ClientError; end

    # Status 429
    class RateLimitError < ClientError; end

    # Status 500
    class InternalServerError < ServerError; end

    # Status 503
    class ServiceUnavailableError < ServerError; end
  end
end

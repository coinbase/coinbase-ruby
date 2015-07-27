module Coinbase
  module Wallet
    def self.format_error(resp)
      error = resp.body && (resp.body['errors'] || resp.body['warnings']).first
      return resp.body unless error
      message = error['message']
      message += " (#{error['url']})" if error["url"]
      message
    end

    def self.check_response_status(resp)
      (resp.body['warnings'] || []).each do |warning|
        message = "WARNING: #{warning['message']}"
        message += " (#{warning['url']})" if warning["url"]
        $stderr.puts message
      end

      # OAuth2 errors
      if resp.status >= 400 && resp.body['error']
        raise APIError, resp.body['error_description']
      end

      # Regular errors
      if resp.body['errors']
        case resp.status
        when 400
          case resp.body['errors'].first['id']
          when 'param_required' then raise ParamRequiredError, format_error(resp)
          when 'invalid_request' then raise InvalidRequestError, format_error(resp)
          when 'personal_details_required' then raise PersonalDetailsRequiredError, format_error(resp)
          end
          raise BadRequestError, format_error(resp)
        when 401
          case resp.body['errors'].first['id']
          when 'authentication_error' then raise AuthenticationError, format_error(resp)
          when 'unverified_email' then raise UnverifiedEmailError, format_error(resp)
          when 'invalid_token' then raise InvalidTokenError, format_error(resp)
          when 'revoked_token' then raise RevokedTokenError, format_error(resp)
          when 'expired_token' then raise ExpiredTokenError, format_error(resp)
          end
          raise AuthenticationError, format_error(resp)
        when 402 then raise TwoFactorRequiredError, format_error(resp)
        when 403 then raise InvalidScopeError, format_error(resp)
        when 404 then raise NotFoundError, format_error(resp)
        when 422 then raise ValidationError, format_error(resp)
        when 429 then raise RateLimitError, format_error(resp)
        when 500 then raise InternalServerError, format_error(resp)
        when 503 then raise ServiceUnavailableError, format_error(resp)
        end
      end

      if resp.status > 400
        raise APIError, "[#{resp.status}] #{resp.body}"
      end
    end

    #
    # Rest API Errors
    #
    class APIError < RuntimeError
    end

    # Status 400
    class BadRequestError < APIError
    end

    class ParamRequiredError < APIError
    end

    class InvalidRequestError < APIError
    end

    class PersonalDetailsRequiredError < APIError
    end

    # Status 401
    class AuthenticationError < APIError
    end

    class UnverifiedEmailError < APIError
    end

    class InvalidTokenError < APIError
    end

    class RevokedTokenError < APIError
    end

    class ExpiredTokenError < APIError
    end

    # Status 402
    class TwoFactorRequiredError < APIError
    end

    # Status 403
    class InvalidScopeError < APIError
    end

    # Status 404
    class NotFoundError < APIError
    end

    # Status 422
    class ValidationError < APIError
    end

    # Status 429
    class RateLimitError < APIError
    end

    # Status 500
    class InternalServerError < APIError
    end

    # Status 503
    class ServiceUnavailableError < APIError
    end
  end
end

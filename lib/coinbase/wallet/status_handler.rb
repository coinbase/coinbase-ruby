# frozen_string_literal: true

module Coinbase
  module Wallet
    class StatusHandler
      #
      # Coinbase::Wallet::StatusHandler
      #
      # The service is responsible for handling api errors based
      # on the response status as well as logging warning messages
      #
      def self.check_response_status(response)
        self.new(response: response).call
      end

      def initialize(response:, logger: Wallet::APILogger)
        self.response = response
        self.logger = logger
      end

      def call
        logger.warn(response)
        handle_oauth_errors
        handle_client_and_server_errors
        handle_regular_errors
      end

      private

      attr_accessor :response, :logger

      def response_status
        @__response_status ||= response.status
      end

      def response_body
        @__response_body ||= response.body
      end

      def response_errors
        @__response_errors ||= response_body['errors']
      end

      def handle_oauth_errors
        if response_status >= 400 && response_body['error']
          raise_exception('APIError', response_body['error_description'])
        end
      end

      def handle_client_and_server_errors
        if response_errors
          case response_status
          when 400..401 then raise_exception(Wallet::CLIENT_ERRORS[response_errors.first['id']] || Wallet::CLIENT_ERRORS[response_status])
          when 400..499 then raise_exception(Wallet::CLIENT_ERRORS[response_status])
          when 500..599 then raise_exception(Wallet::SERVER_ERRORS[response_status])
          else raise_exception
          end
        end
      end

      def handle_regular_errors
        if response_status > 400
          raise_exception
        end
      end

      def error_message
        error = response_body && (response_body['errors'] || response_body['warnings']).first
        return response_body unless error
        message = error['message']
        message += " (#{error['url']})" if error["url"]
        message
      end

      def raise_exception(error_klass = 'APIError', message = error_message)
        raise Wallet.const_get(error_klass), "[#{response_status}] #{message}"
      end
    end
  end
end

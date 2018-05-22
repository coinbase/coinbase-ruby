# frozen_string_literal: true

module Coinbase
  module Wallet
    class StatusMiddleware
      #
      # Coinbase::Wallet::StatusMiddleware
      #
      # The service is responsible for handling api errors based
      # on the response status as well as logging warning messages
      #
      def self.check_response_status(response)
        self.new(response: response).call
      end

      def initialize(response:)
        self.response = response
      end

      def call
        log_warning_messages
        handle_oauth_errors
        handle_client_and_server_errors
        handle_regular_errors
      end

      private

      attr_accessor :response

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
          raise Wallet::APIError.new(response_body['error_description'])
        end
      end

      def handle_client_and_server_errors
        if response_errors
          case response_status
          when 400..401 then raise_exception(Wallet::CLIENT_ERRORS[response_errors.first['id']] || Wallet::CLIENT_ERRORS[response_status])
          when 400..499 then raise_exception(Wallet::CLIENT_ERRORS[response_status])
          when 500..599 then raise_exception(Wallet::SERVER_ERRORS[response_status])
          else raise Wallet::APIError.new("[#{response_status}] #{response_body}")
          end
        end
      end

      def handle_regular_errors
        if response_status > 400
          raise Wallet::APIError.new("[#{response_status}] #{response_body}")
        end
      end

      def log_warning_messages
        (response_body['warnings'] || []).each do |warning|
          message = "WARNING: #{warning['message']}"
          message += " (#{warning['url']})" if warning["url"]
          $stderr.puts message
        end
      end

      def error_message
        error = response_body && (response_body['errors'] || response_body['warnings']).first
        return response_body unless error
        message = error['message']
        message += " (#{error['url']})" if error["url"]
        message
      end

      def raise_exception(error_klass)
        raise Wallet.const_get(error_klass), error_message
      end
    end
  end
end

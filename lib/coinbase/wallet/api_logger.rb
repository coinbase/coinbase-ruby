# frozen_string_literal: true

module Coinbase
  module Wallet
    class APILogger
      def self.warn(response)
        (response.body['warnings'] || []).each do |warning|
          message = "WARNING: #{warning['message']}"
          message += " (#{warning['url']})" if warning["url"]
          $stderr.puts message
        end
      end
    end
  end
end

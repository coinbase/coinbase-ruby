module Coinbase
  module Wallet
    # Encapsulate data for an API response
    class APIResponse
      attr_reader :received_at
      attr_accessor :client
      attr_accessor :method
      attr_accessor :params

      def initialize(resp)
        @received_at = Time.now
        @response = resp
      end

      def raw
        @response
      end

      def body
        raise NotImplementedError
      end
      alias_method :data, :body

      def body=(body)
        raise NotImplementedError
      end

      def headers
        raise NotImplementedError
      end

      def status
        raise NotImplementedError
      end

      def has_more?
        body.has_key?('pagination') && body['pagination']['next_uri'] != nil
      end
    end
  end
end

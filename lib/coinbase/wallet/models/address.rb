module Coinbase
  module Wallet
    class Address < APIObject
      def transactions(params = {})
        @client.get("#{self['resource_path']}/transactions", params) do |resp|
          out = resp.data.map { |item| Transaction.new(self, item) }
          yield(out, resp) if block_given?
        end
      end
    end
  end
end

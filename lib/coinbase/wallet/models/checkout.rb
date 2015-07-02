module Coinbase
  module Wallet
    class Checkout < APIObject
      def orders(params = {})
        @client.get("#{self['resource_path']}/orders", params) do |resp|
          out = resp.data.map { |item| Order.new(self, item) }
          yield(out, resp) if block_given?
        end
      end

      def create_order(params = {})
        @client.post("#{self['resource_path']}/orders", params) do |resp|
          out = Order.new(self, resp.data)
          yield(out, resp) if block_given?
        end
      end
    end
  end
end

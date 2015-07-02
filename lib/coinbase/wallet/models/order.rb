module Coinbase
  module Wallet
    class Order < APIObject
      def refund!(params = {})
        @client.post("#{self['resource_path']}/refund", params) do |resp|
          update(resp.data)
          yield(resp.data, resp) if block_given?
        end
      end
    end
  end
end

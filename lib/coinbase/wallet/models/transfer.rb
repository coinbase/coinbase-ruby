module Coinbase
  module Wallet
    class Transfer < APIObject
      def commit!(params = {})
        @client.post("#{self['resource_path']}/commit", params) do |data, resp|
          update(data)
          yield(data, resp) if block_given?
        end
      end
    end
  end
end


module Coinbase
  module Wallet
    class User < APIObject
    end

    class CurrentUser < User
      def update!(params = {})
        @client.update_current_user(params) do |data, resp|
          update(resp.data)
          yield(resp.data, resp) if block_given?
        end
      end
    end
  end
end

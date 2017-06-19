module Coinbase
  module Wallet
    class Account < APIObject
      def update!(params = {})
        @client.update_account(self['id'], params) do |data, resp|
          update(data)
          yield(data, resp) if block_given?
        end
      end

      def make_primary!(params = {})
        @client.set_primary_account(self['id'], params) do |data, resp|
          update(data)
          yield(data, resp) if block_given?
        end
      end

      def delete!(params = {})
        @client.delete_account(self['id'], params) do |data, resp|
          yield(data, resp) if block_given?
        end
      end

      #
      # Addresses
      #
      def addresses(params = {})
        @client.addresses(self['id'], params) do |data, resp|
          yield(data, resp) if block_given?
        end
      end

      def address(address_id, params = {})
        @client.address(self['id'], address_id, params) do |data, resp|
          yield(data, resp) if block_given?
        end
      end

      def address_transactions(address_id, params = {})
        @client.address_transactions(self['id'], address_id, params) do |data, resp|
          yield(data, resp) if block_given?
        end
      end

      def create_address(params = {})
        @client.create_address(self['id'], params) do |data, resp|
          yield(data, resp) if block_given?
        end
      end

      #
      # Transactions
      #
      def transactions(params = {})
        @client.transactions(self['id'], params) do |data, resp|
          yield(data, resp) if block_given?
        end
      end

      def transaction(transaction_id, params = {})
        @client.transaction(self['id'], transaction_id, params) do |data, resp|
          yield(data, resp) if block_given?
        end
      end

      def send(params = {})
        @client.send(self['id'], params) do |data, resp|
          yield(data, resp) if block_given?
        end
      end

      def transfer(params = {})
        @client.transfer(self['id'], params) do |data, resp|
          yield(data, resp) if block_given?
        end
      end

      def request(params = {})
        @client.request(self['id'], params) do |data, resp|
          yield(data, resp) if block_given?
        end
      end

      #
      # Buys
      #
      def list_buys(params = {})
        @client.list_buys(self['id'], params) do |data, resp|
          yield(data, resp) if block_given?
        end
      end

      def list_buy(transaction_id, params = {})
        @client.list_buy(self['id'], transaction_id, params) do |data, resp|
          yield(data, resp) if block_given?
        end
      end

      def buy(params = {})
        @client.buy(self['id'], params) do |data, resp|
          yield(data, resp) if block_given?
        end
      end

      def commit_buy(transaction_id, params = {})
        @client.commit_buy(self['id'], transaction_id, params) do |data, resp|
          yield(data, resp) if block_given?
        end
      end

      #
      # Sells
      #
      def list_sells(params = {})
        @client.list_sells(self['id'], params) do |data, resp|
          yield(data, resp) if block_given?
        end
      end

      def list_sell(transaction_id, params = {})
        @client.list_sell(self['id'], transaction_id, params) do |data, resp|
          yield(data, resp) if block_given?
        end
      end

      def sell(params = {})
        @client.sell(self['id'], params) do |data, resp|
          yield(data, resp) if block_given?
        end
      end

      def commit_sell(transaction_id, params = {})
        @client.commit_sell(self['id'], transaction_id, params) do |data, resp|
          yield(data, resp) if block_given?
        end
      end

      #
      # Deposit
      #
      def list_deposits(params = {})
        @client.list_deposits(self['id'], params) do |data, resp|
          yield(data, resp) if block_given?
        end
      end

      def list_deposit(transaction_id, params = {})
        @client.list_deposit(self['id'], transaction_id, params) do |data, resp|
          yield(data, resp) if block_given?
        end
      end

      def deposit(params = {})
        @client.deposit(self['id'], params) do |data, resp|
          yield(data, resp) if block_given?
        end
      end

      def commit_deposit(transaction_id, params = {})
        @client.commit_deposit(self['id'], transaction_id, params) do |data, resp|
          yield(data, resp) if block_given?
        end
      end

      #
      # Withdrawals
      #
      def list_withdrawals(params = {})
        @client.list_withdrawals(self['id'], params) do |data, resp|
          yield(data, resp) if block_given?
        end
      end

      def list_withdrawal(transaction_id, params = {})
        @client.list_withdrawal(self['id'], transaction_id, params) do |data, resp|
          yield(data, resp) if block_given?
        end
      end

      def withdraw(params = {})
        @client.withdraw(self['id'], params) do |data, resp|
          yield(data, resp) if block_given?
        end
      end

      def commit_withdrawal(transaction_id, params = {})
        @client.commit_withdrawal(self['id'], transaction_id, params) do |data, resp|
          yield(data, resp) if block_given?
        end
      end
    end
  end
end

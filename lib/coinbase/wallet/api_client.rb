module Coinbase
  module Wallet
    class APIClient
      def auth_headers(method, path, body)
        raise NotImplementedError, "APIClient is not intended to be used directly"
      end

      #
      # Market Data
      #
      def currencies(params = {})
        out = nil
        get("/v2/currencies", params) do |data, resp|
          out = resp.data.map { |item| APIObject.new(self, item) }
          yield(data, resp) if block_given?
        end
        out
      end

      def exchange_rates(params = {})
        out = nil
        get("/v2/exchange-rates", params) do |data, resp|
          out = resp.data.map { |item| APIObject.new(self, item) }
          yield(data, resp) if block_given?
        end
        out
      end

      def buy_price(params = {})
        out = nil
        get("/v2/prices/buy", params) do |data, resp|
          out = APIObject.new(self, resp.data)
          yield(data, resp) if block_given?
        end
        out
      end

      def sell_price(params = {})
        out = nil
        get("/v2/prices/sell", params) do |data, resp|
          out = APIObject.new(self, resp.data)
          yield(data, resp) if block_given?
        end
        out
      end
      def spot_price(params = {})
        out = nil
        get("/v2/prices/spot", params) do |data, resp|
          out = APIObject.new(self, resp.data)
          yield(data, resp) if block_given?
        end
        out
      end

      def time(params = {})
        out = nil
        get("/v2/time", params) do |data, resp|
          out = APIObject.new(self, resp.data)
          yield(data, resp) if block_given?
        end
        out
      end

      #
      # Users
      #
      def user(user_id, params = {})
        out = nil
        get("/v2/users/#{user_id}", params) do |data, resp|
          out = User.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def current_user(params = {})
        out = nil
        get("/v2/user", params) do |data, resp|
          out = CurrentUser.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def auth_info(params = {})
        out = nil
        get("/v2/user/auth") do |data, resp|
          out = APIObject.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def update_current_user(params = {})
        out = nil
        put("/v2/user", params) do |data, resp|
          out = CurrentUser.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      #
      # Accounts
      #
      def accounts(params = {})
        out = nil
        get("/v2/accounts", params) do |data, resp|
          out = data.map { |item| Account.new(self, item) }
          yield(out, resp) if block_given?
        end
        out
      end

      def account(account_id, params = {})
        out = nil
        get("/v2/accounts/#{account_id}", params) do |data, resp|
          out = Account.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def primary_account(params = {})
        out = nil
        get("/v2/accounts/primary", params) do |data, resp|
          out = Account.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def set_primary_account(account_id, params = {})
        out = nil
        post("/v2/accounts/#{account_id}/primary", params) do |data, resp|
          out = Account.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def create_account(params = {})
        out = nil
        post("/v2/accounts", params) do |data, resp|
          out = Account.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def update_account(account_id, params = {})
        out = nil
        put("/v2/accounts/#{account_id}", params) do |data, resp|
          out = Account.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def delete_account(account_id, params = {})
        out = nil
        delete("/v2/accounts/#{account_id}", params) do |data, resp|
          out = APIObject.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      #
      # Addresses
      #
      def addresses(account_id, params = {})
        out = nil
        get("/v2/accounts/#{account_id}/addresses", params) do |data, resp|
          out = resp.data.map { |item| APIObject.new(self, item) }
          yield(data, resp) if block_given?
        end
        out
      end

      def address(account_id, address_id, params = {})
        out = nil
        get("/v2/accounts/#{account_id}/addresses/#{address_id}", params) do |data, resp|
          out = APIObject.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def create_address(account_id, params = {})
        out = nil
        post("/v2/accounts/#{account_id}/addresses", params) do |data, resp|
          out = APIObject.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      #
      # Transactions
      #
      def transactions(account_id, params = {})
        out = nil
        get("/v2/accounts/#{account_id}/transactions", params) do |data, resp|
          out = resp.data.map { |item| Transaction.new(self, item) }
          yield(data, resp) if block_given?
        end
        out
      end

      def transaction(account_id, transaction_id, params = {})
        out = nil
        get("/v2/accounts/#{account_id}/transactions/#{transaction_id}", params) do |data, resp|
          out = Transaction.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def send(account_id, params = {})
        [ :to, :amount ].each do |param|
          raise APIError, "Missing parameter: #{param}" unless params.include? param
        end
        params['type'] = 'send'

        out = nil
        post("/v2/accounts/#{account_id}/transactions", params) do |data, resp|
          out = Transaction.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def transfer(account_id, params = {})
        [ :to, :amount ].each do |param|
          raise APIError, "Missing parameter: #{param}" unless params.include? param
        end
        params['type'] = 'transfer'

        out = nil
        post("/v2/accounts/#{account_id}/transactions", params) do |data, resp|
          out = Transaction.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def request(account_id, params = {})
        [ :to, :amount, :currency ].each do |param|
          raise APIError, "Missing parameter: #{param}" unless params.include? param
        end
        params['type'] = 'request'

        out = nil
        post("/v2/accounts/#{account_id}/transactions", params) do |data, resp|
          out = Request.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def resend_request(account_id, transaction_id, params = {})
        out = nil
        post("/v2/accounts/#{account_id}/transactions/#{transaction_id}/resend", params) do |data, resp|
          out = APIObject.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def cancel_request(account_id, transaction_id, params = {})
        out = nil
        delete("/v2/accounts/#{account_id}/transactions/#{transaction_id}", params) do |data, resp|
          out = APIObject.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def complete_request(account_id, transaction_id, params = {})
        out = nil
        post("/v2/accounts/#{account_id}/transactions/#{transaction_id}/complete", params) do |data, resp|
          out = APIObject.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      #
      # Buys
      #
      def list_buys(account_id, pararms={})
        out = nil
        get("/v2/accounts/#{account_id}/buys") do |data, resp|
          out = resp.data.map { |item| Transfer.new(self, item) }
          yield(data, resp) if block_given?
        end
        out
      end

      def list_buy(account_id, transaction_id, params = {})
        out = nil
        get("/v2/accounts/#{account_id}/buys/#{transaction_id}") do |data, resp|
          out = Transfer.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def buy(account_id, params = {})
        [ :amount ].each do |param|
          raise APIError, "Missing parameter: #{param}" unless params.include? param
        end

        out = nil
        post("/v2/accounts/#{account_id}/buys") do |data, resp|
          out = Transfer.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def commit_buy(account_id, transaction_id, params = {})
        out = nil
        post("/v2/accounts/#{account_id}/buys/#{transaction_id}/commit") do |data, resp|
          out = Transfer.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      #
      # Sells
      #
      def list_sells(account_id, params = {})
        out = nil
        get("/v2/accounts/#{account_id}/sells") do |data, resp|
          out = resp.data.map { |item| Transfer.new(self, item) }
          yield(data, resp) if block_given?
        end
        out
      end

      def list_sell(account_id, transaction_id, params = {})
        out = nil
        get("/v2/accounts/#{account_id}/sells/#{transaction_id}") do |data, resp|
          out = Transfer.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def sell(account_id, params = {})
        [ :amount ].each do |param|
          raise APIError, "Missing parameter: #{param}" unless params.include? param
        end

        out = nil
        post("/v2/accounts/#{account_id}/sells") do |data, resp|
          out = Transfer.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def commit_sell(account_id, transaction_id, params = {})
        out = nil
        post("/v2/accounts/#{account_id}/sells/#{transaction_id}/commit") do |data, resp|
          out = Transfer.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      #
      # Deposits
      #
      def list_deposits(account_id, pararms={})
        out = nil
        get("/v2/accounts/#{account_id}/deposits") do |data, resp|
          out = resp.data.map { |item| Transfer.new(self, item) }
          yield(data, resp) if block_given?
        end
        out
      end

      def list_deposit(account_id, transaction_id, params = {})
        out = nil
        get("/v2/accounts/#{account_id}/deposits/#{transaction_id}") do |data, resp|
          out = Transfer.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def deposit(account_id, params = {})
        [ :amount ].each do |param|
          raise APIError, "Missing parameter: #{param}" unless params.include? param
        end

        out = nil
        post("/v2/accounts/#{account_id}/deposits") do |data, resp|
          out = Transfer.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def commit_deposit(account_id, transaction_id, params = {})
        out = nil
        post("/v2/accounts/#{account_id}/deposits/#{transaction_id}/commit") do |data, resp|
          out = APIObject.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      #
      # withdrawals
      #
      def list_withdrawals(account_id, pararms={})
        out = nil
        get("/v2/accounts/#{account_id}/withdrawals") do |data, resp|
          out = resp.data.map { |item| Transfer.new(self, item) }
          yield(data, resp) if block_given?
        end
        out
      end

      def list_withdrawal(account_id, transaction_id, params = {})
        out = nil
        get("/v2/accounts/#{account_id}/withdrawals/#{transaction_id}") do |data, resp|
          out = Transfer.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def withdraw(account_id, params = {})
        [ :amount ].each do |param|
          raise APIError, "Missing parameter: #{param}" unless params.include? param
        end

        out = nil
        post("/v2/accounts/#{account_id}/withdrawals") do |data, resp|
          out = Transfer.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def commit_withdrawal(account_id, transaction_id, params = {})
        out = nil
        post("/v2/accounts/#{account_id}/withdrawals/#{transaction_id}/commit") do |data, resp|
          out = APIObject.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      #
      # Payment Methods
      #
      def payment_methods(params = {})
        out = nil
        get("/v2/payment-methods", params) do |data, resp|
          out = resp.data.map { |item| APIObject.new(self, item) }
          yield(out, resp) if block_given?
        end
        out
      end

      def payment_method(payment_method_id, params = {})
        out = nil
        get("/v2/payment-methods/#{payment_method_id}", params) do |data, resp|
          out = APIObject.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      #
      # Merchants
      #
      def merchant(merchant_id, params = {})
        out = nil
        get("/v2/merchants/#{merchant_id}", params) do |data, resp|
          out = APIObject.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      #
      # Orders
      #
      def orders(params = {})
        out = nil
        get("/v2/orders", params) do |data, resp|
          out = resp.data.map { |item| Order.new(self, item) }
          yield(out, resp) if block_given?
        end
        out
      end

      def order(order_id, params = {})
        out = nil
        get("/v2/orders/#{order_id}", params) do |data, resp|
          out = Order.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def create_order(params = {})
        [ :amount, :currency, :name ].each do |param|
          fail APIError, "Missing parameter: #{param}" unless params.include? param
        end

        out = nil
        post("/v2/orders") do |data, resp|
          out = Order.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def refund_order(order_id, params={})
        [ :currency ].each do |param|
          fail APIError, "Missing parameter: #{param}" unless params.include? param
        end

        out = nil
        post("/v2/orders/#{order_id}/refund") do |data, resp|
          out = Order.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      #
      # Checkouts
      #
      def checkouts(params = {})
        out = nil
        get("/v2/checkouts", params) do |data, resp|
          out = resp.data.map { |item| Checkout.new(self, item) }
          yield(out, resp) if block_given?
        end
        out
      end

      def checkout(checkout_id, params = {})
        out = nil
        get("/v2/checkouts/#{checkout_id}", params) do |data, resp|
          out = Checkout.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def create_checkout(params = {})
        [ :amount, :currency, :name ].each do |param|
          fail APIError, "Missing parameter: #{param}" unless params.include? param
        end

        out = nil
        post("/v2/checkouts", params) do |data, resp|
          out = Checkout.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def checkout_orders(checkout_id, params = {})
        out = nil
        get("/v2/checkouts/#{checkout_id}/orders", params) do |data, resp|
          out = resp.data.map { |item| Order.new(self, item) }
          yield(out, resp) if block_given?
        end
        out
      end

      def create_checkout_order(checkout_id, params={})
        out = nil
        post("/v2/checkouts/#{checkout_id}/orders", params) do |data, resp|
          out = Order.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      #
      # HTTP Stuff
      #
      def get(path, params = {})
        uri = path
        if params.count > 0
          uri += "?#{URI.encode_www_form(params)}"
        end

        headers = {}
        if params.has_key? :two_factor_token
          headers['CB-2FA-TOKEN'] = params[:two_factor_token]
          params.delete(:two_factor_token)
        end

        http_verb('GET', uri, nil, headers) do |resp|
          if params[:fetch_all] == true &&
            resp.body.has_key?('pagination') &&
            resp.body['pagination']['next_uri'] != nil
              params[:starting_after] = resp.body['data'].last['id']
              get(path, params) do |p_data, p_resp|
                yield(resp.body['data'] + p_data, resp)
              end
          else
            yield(resp.body['data'], resp)
          end
        end
      end

      def put(path, params = {})
        headers = {}
        if params.has_key? :two_factor_token
          headers['CB-2FA-TOKEN'] = params[:two_factor_token]
          params.delete(:two_factor_token)
        end

        http_verb('PUT', path, params.to_json, headers) do |resp|
          yield(resp.body['data'], resp)
        end
      end

      def post(path, params = {})
        headers = {}
        if params.has_key? :two_factor_token
          headers['CB-2FA-TOKEN'] = params[:two_factor_token]
          params.delete(:two_factor_token)
        end

        http_verb('POST', path, params.to_json, headers) do |resp|
          yield(resp.body['data'], resp)
        end
      end

      def delete(path, params = {})
        headers = {}
        if params.has_key? :two_factor_token
          headers['CB-2FA-TOKEN'] = params[:two_factor_token]
          params.delete(:two_factor_token)
        end

        http_verb('DELETE', path, nil, headers) do |resp|
          yield(resp.body['data'], resp)
        end
      end
    end
  end
end

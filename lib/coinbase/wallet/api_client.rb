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
        get("/v2/currencies", params) do |resp|
          out = resp.data.map { |item| APIObject.new(self, item) }
          yield(out, resp) if block_given?
        end
        out
      end

      def exchange_rates(params = {})
        out = nil
        get("/v2/exchange-rates", params) do |resp|
          out = APIObject.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def buy_price(params = {})
        out = nil
        pair = determine_currency_pair(params)

        get("/v2/prices/#{pair}/buy", params) do |resp|
          out = APIObject.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def sell_price(params = {})
        out = nil
        pair = determine_currency_pair(params)

        get("/v2/prices/#{pair}/sell", params) do |resp|
          out = APIObject.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def spot_price(params = {})
        out = nil
        pair = determine_currency_pair(params)

        get("/v2/prices/#{pair}/spot", params) do |resp|
          out = APIObject.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def historic_prices(params = {})
        out = nil
        get("/v2/prices/historic", params) do |resp|
          out = APIObject.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def time(params = {})
        out = nil
        get("/v2/time", params) do |resp|
          out = APIObject.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      #
      # Users
      #
      def user(user_id, params = {})
        out = nil
        get("/v2/users/#{user_id}", params) do |resp|
          out = User.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def current_user(params = {})
        out = nil
        get("/v2/user", params) do |resp|
          out = CurrentUser.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def auth_info(params = {})
        out = nil
        get("/v2/user/auth", params) do |resp|
          out = APIObject.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def update_current_user(params = {})
        out = nil
        put("/v2/user", params) do |resp|
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
        get("/v2/accounts", params) do |resp|
          out = resp.data.map { |item| Account.new(self, item) }
          yield(out, resp) if block_given?
        end
        out
      end

      def account(account_id, params = {})
        out = nil
        get("/v2/accounts/#{account_id}", params) do |resp|
          out = Account.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def primary_account(params = {})
        out = nil
        get("/v2/accounts/primary", params) do |resp|
          out = Account.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def set_primary_account(account_id, params = {})
        out = nil
        post("/v2/accounts/#{account_id}/primary", params) do |resp|
          out = Account.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def create_account(params = {})
        out = nil
        post("/v2/accounts", params) do |resp|
          out = Account.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def update_account(account_id, params = {})
        out = nil
        put("/v2/accounts/#{account_id}", params) do |resp|
          out = Account.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def delete_account(account_id, params = {})
        out = nil
        delete("/v2/accounts/#{account_id}", params) do |resp|
          out = APIObject.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      #
      # Notifications
      #
      def notifications(params = {})
        out = nil
        get("/v2/notifications", params) do |resp|
          out = resp.data.map { |item| APIObject.new(self, item) }
          yield(out, resp) if block_given?
        end
        out
      end

      def notification(notification_id, params = {})
        out = nil
        get("/v2/notifications/#{notification_id}", params) do |resp|
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
        get("/v2/accounts/#{account_id}/addresses", params) do |resp|
          out = resp.data.map { |item| Address.new(self, item) }
          yield(out, resp) if block_given?
        end
        out
      end

      def address(account_id, address_id, params = {})
        out = nil
        get("/v2/accounts/#{account_id}/addresses/#{address_id}", params) do |resp|
          out = Address.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def address_transactions(account_id, address_id, params = {})
        out = nil
        get("/v2/accounts/#{account_id}/addresses/#{address_id}/transactions", params) do |resp|
          out = resp.data.map { |item| Transaction.new(self, item) }
          yield(out, resp) if block_given?
        end
        out
      end

      def create_address(account_id, params = {})
        out = nil
        post("/v2/accounts/#{account_id}/addresses", params) do |resp|
          out = Address.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      #
      # Transactions
      #
      def transactions(account_id, params = {})
        out = nil
        get("/v2/accounts/#{account_id}/transactions", params) do |resp|
          out = resp.data.map { |item| Transaction.new(self, item) }
          yield(out, resp) if block_given?
        end
        out
      end

      def transaction(account_id, transaction_id, params = {})
        out = nil
        get("/v2/accounts/#{account_id}/transactions/#{transaction_id}", params) do |resp|
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
        post("/v2/accounts/#{account_id}/transactions", params) do |resp|
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
        post("/v2/accounts/#{account_id}/transactions", params) do |resp|
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
        post("/v2/accounts/#{account_id}/transactions", params) do |resp|
          out = Request.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def resend_request(account_id, transaction_id, params = {})
        out = nil
        post("/v2/accounts/#{account_id}/transactions/#{transaction_id}/resend", params) do |resp|
          out = APIObject.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def cancel_request(account_id, transaction_id, params = {})
        out = nil
        delete("/v2/accounts/#{account_id}/transactions/#{transaction_id}", params) do |resp|
          out = APIObject.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def complete_request(account_id, transaction_id, params = {})
        out = nil
        post("/v2/accounts/#{account_id}/transactions/#{transaction_id}/complete", params) do |resp|
          out = APIObject.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      #
      # Buys
      #
      def list_buys(account_id, params={})
        out = nil
        get("/v2/accounts/#{account_id}/buys", params) do |resp|
          out = resp.data.map { |item| Transfer.new(self, item) }
          yield(out, resp) if block_given?
        end
        out
      end

      def list_buy(account_id, transaction_id, params = {})
        out = nil
        get("/v2/accounts/#{account_id}/buys/#{transaction_id}", params) do |resp|
          out = Transfer.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def buy(account_id, params = {})
        raise APIError, "Missing parameter: 'amount' or 'total'" unless params.include? :amount or params.include? :total

        out = nil
        post("/v2/accounts/#{account_id}/buys", params) do |resp|
          out = Transfer.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def commit_buy(account_id, transaction_id, params = {})
        out = nil
        post("/v2/accounts/#{account_id}/buys/#{transaction_id}/commit", params) do |resp|
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
        get("/v2/accounts/#{account_id}/sells", params) do |resp|
          out = resp.data.map { |item| Transfer.new(self, item) }
          yield(out, resp) if block_given?
        end
        out
      end

      def list_sell(account_id, transaction_id, params = {})
        out = nil
        get("/v2/accounts/#{account_id}/sells/#{transaction_id}", params) do |resp|
          out = Transfer.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def sell(account_id, params = {})
        raise APIError, "Missing parameter: 'amount' or 'total'" unless params.include? :amount or params.include? :total

        out = nil
        post("/v2/accounts/#{account_id}/sells", params) do |resp|
          out = Transfer.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def commit_sell(account_id, transaction_id, params = {})
        out = nil
        post("/v2/accounts/#{account_id}/sells/#{transaction_id}/commit", params) do |resp|
          out = Transfer.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      #
      # Deposits
      #
      def list_deposits(account_id, params={})
        out = nil
        get("/v2/accounts/#{account_id}/deposits", params) do |resp|
          out = resp.data.map { |item| Transfer.new(self, item) }
          yield(out, resp) if block_given?
        end
        out
      end

      def list_deposit(account_id, transaction_id, params = {})
        out = nil
        get("/v2/accounts/#{account_id}/deposits/#{transaction_id}", params) do |resp|
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
        post("/v2/accounts/#{account_id}/deposits", params) do |resp|
          out = Transfer.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def commit_deposit(account_id, transaction_id, params = {})
        out = nil
        post("/v2/accounts/#{account_id}/deposits/#{transaction_id}/commit", params) do |resp|
          out = APIObject.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      #
      # withdrawals
      #
      def list_withdrawals(account_id, params={})
        out = nil
        get("/v2/accounts/#{account_id}/withdrawals", params) do |resp|
          out = resp.data.map { |item| Transfer.new(self, item) }
          yield(out, resp) if block_given?
        end
        out
      end

      def list_withdrawal(account_id, transaction_id, params = {})
        out = nil
        get("/v2/accounts/#{account_id}/withdrawals/#{transaction_id}", params) do |resp|
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
        post("/v2/accounts/#{account_id}/withdrawals", params) do |resp|
          out = Transfer.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def commit_withdrawal(account_id, transaction_id, params = {})
        out = nil
        post("/v2/accounts/#{account_id}/withdrawals/#{transaction_id}/commit", params) do |resp|
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
        get("/v2/payment-methods", params) do |resp|
          out = resp.data.map { |item| APIObject.new(self, item) }
          yield(out, resp) if block_given?
        end
        out
      end

      def payment_method(payment_method_id, params = {})
        out = nil
        get("/v2/payment-methods/#{payment_method_id}", params) do |resp|
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
        get("/v2/merchants/#{merchant_id}", params) do |resp|
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
        get("/v2/orders", params) do |resp|
          out = resp.data.map { |item| Order.new(self, item) }
          yield(out, resp) if block_given?
        end
        out
      end

      def order(order_id, params = {})
        out = nil
        get("/v2/orders/#{order_id}", params) do |resp|
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
        post("/v2/orders", params) do |resp|
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
        post("/v2/orders/#{order_id}/refund", params) do |resp|
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
        get("/v2/checkouts", params) do |resp|
          out = resp.data.map { |item| Checkout.new(self, item) }
          yield(out, resp) if block_given?
        end
        out
      end

      def checkout(checkout_id, params = {})
        out = nil
        get("/v2/checkouts/#{checkout_id}", params) do |resp|
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
        post("/v2/checkouts", params) do |resp|
          out = Checkout.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      def checkout_orders(checkout_id, params = {})
        out = nil
        get("/v2/checkouts/#{checkout_id}/orders", params) do |resp|
          out = resp.data.map { |item| Order.new(self, item) }
          yield(out, resp) if block_given?
        end
        out
      end

      def create_checkout_order(checkout_id, params={})
        out = nil
        post("/v2/checkouts/#{checkout_id}/orders", params) do |resp|
          out = Order.new(self, resp.data)
          yield(out, resp) if block_given?
        end
        out
      end

      #
      # HTTP Stuff
      #
      def get(path, params)
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
              get(path, params) do |page|
                body = resp.body
                body['data'] += page.data
                resp.body = body
                yield(resp)
              end
          else
            yield(resp)
          end
        end
      end

      def put(path, params)
        headers = {}
        if params.has_key? :two_factor_token
          headers['CB-2FA-TOKEN'] = params[:two_factor_token]
          params.delete(:two_factor_token)
        end

        http_verb('PUT', path, params.to_json, headers) do |resp|
          yield(resp)
        end
      end

      def post(path, params)
        headers = {}
        if params.has_key? :two_factor_token
          headers['CB-2FA-TOKEN'] = params[:two_factor_token]
          params.delete(:two_factor_token)
        end

        http_verb('POST', path, params.to_json, headers) do |resp|
          yield(resp)
        end
      end

      def delete(path, params)
        headers = {}
        if params.has_key? :two_factor_token
          headers['CB-2FA-TOKEN'] = params[:two_factor_token]
          params.delete(:two_factor_token)
        end

        http_verb('DELETE', path, nil, headers) do |resp|
          yield(resp)
        end
      end

      CALLBACK_DIGEST = OpenSSL::Digest.new("SHA256")
      def self.verify_callback(body, signature)
        return false unless callback_signing_public_key
        callback_signing_public_key.verify(CALLBACK_DIGEST, signature.unpack("m0")[0], body)
      rescue OpenSSL::PKey::RSAError, ArgumentError
        false
      end

      def self.callback_signing_public_key
        @@callback_signing_public_key ||= nil
        return @@callback_signing_public_key if @@callback_signing_public_key
        path = File.expand_path(File.join(File.dirname(__FILE__), 'coinbase-callback.pub'))
        @@callback_signing_public_key = OpenSSL::PKey::RSA.new(File.read(path))
      end

      def callback_signing_public_key
        Coinbase::Wallet::APIClient.callback_signing_public_key
      end

      def verify_callback(body, signature)
        Coinbase::Wallet::APIClient.verify_callback(body, signature)
      end

      def self.whitelisted_certificates
        path = File.expand_path(File.join(File.dirname(__FILE__), 'ca-coinbase.crt'))

        certs = [ [] ]
        File.readlines(path).each do |line|
          next if ["\n","#"].include?(line[0])
          certs.last << line
          certs << [] if line == "-----END CERTIFICATE-----\n"
        end

        result = OpenSSL::X509::Store.new

        certs.each do |lines|
          next if lines.empty?
          cert = OpenSSL::X509::Certificate.new(lines.join)
          result.add_cert(cert)
        end

        result
      end

      private

      def determine_currency_pair(params)
        Coinbase::Util.determine_currency_pair(params)
      end
    end
  end
end

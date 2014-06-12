require 'httparty'
require 'multi_json'
require 'hashie'
require 'money'
require 'monetize'
require 'time'
require 'securerandom'

module Coinbase
  class Client
    include HTTParty

    BASE_URI = 'https://coinbase.com/api/v1'

    def initialize(api_key='', api_secret='', options={})
      @api_key = api_key
      @api_secret = api_secret

      # defaults
      options[:base_uri] ||= BASE_URI
      @base_uri = options[:base_uri]
      options[:format]   ||= :json
      options.each do |k,v|
        self.class.send k, v
      end
    end

    # Account

    def balance options={}
      get '/account/balance', options
    end

    def accounts options={}
      get '/accounts', options
    end

    # Buttons

    def create_button name, price, description=nil, custom=nil, options={}
      options[:button]                        ||= {}
      options[:button][:name]                 ||= name
      price = price.to_money("BTC") unless price.is_a?(Money)
      options[:button][:price_string]         ||= price.to_s
      options[:button][:price_currency_iso]   ||= price.currency.iso_code
      options[:button][:description]          ||= description
      options[:button][:custom]               ||= custom
      r = post '/buttons', options
      if r.success?
        r.embed_html = case options[:button_mode]
                       when 'page'
                         %[<a href="https://coinbase.com/checkouts/#{r.button.code}" target="_blank"><img alt="#{r.button.text}" src="https://coinbase.com/assets/buttons/#{r.button.style}.png"></a>]
                       when 'iframe'
                          %[<iframe src="https://coinbase.com/inline_payments/#{r.button.code}" style="width:500px;height:160px;border:none;box-shadow:0 1px 3px rgba(0,0,0,0.25);overflow:hidden;" scrolling="no" allowtransparency="true" frameborder="0"></iframe>]
                       else
                         %[<div class="coinbase-button" data-code="#{r.button.code}"></div><script src="https://coinbase.com/assets/button.js" type="text/javascript"></script>]
                       end
      end
      r
    end

    def create_order_for_button button_id
      post "/buttons/#{button_id}/create_order"
    end

    # Addresses

    def addresses page=1, options={}
      get '/addresses', {page: page}.merge(options)
    end

    # Orders

    def orders page=1, options={}
      get '/orders', {page: page}.merge(options)
    end

    def order id, options={}
      get "/orders/#{id}", options
    end

    # Transactions

    def transactions page=1, options={}
      r = get '/transactions', {page: page}.merge(options)
      r.transactions ||= []
      r
    end

    def transaction transaction_id, options={}
      get "/transactions/#{transaction_id}", options
    end

    def send_money to, amount, notes=nil, options={}
      options[:transaction]                         ||= {}
      options[:transaction][:to]                    ||= to
      amount = amount.to_money("BTC") unless amount.is_a?(Money)
      options[:transaction][:amount_string]         ||= amount.to_s
      options[:transaction][:amount_currency_iso]   ||= amount.currency.iso_code
      options[:transaction][:notes]                 ||= notes

      post '/transactions/send_money', options
    end

    def request_money from, amount, notes=nil, options={}
      options[:transaction]                         ||= {}
      options[:transaction][:from]                  ||= from
      amount = amount.to_money("BTC") unless amount.is_a?(Money)
      options[:transaction][:amount_string]         ||= amount.to_s
      options[:transaction][:amount_currency_iso]   ||= amount.currency.iso_code
      options[:transaction][:notes]                 ||= notes

      post '/transactions/request_money', options
    end

    def resend_request transaction_id
      put "/transactions/#{transaction_id}/resend_request"
    end

    def cancel_request transaction_id
      delete "/transactions/#{transaction_id}/cancel_request"
    end

    def complete_request transaction_id
      put "/transactions/#{transaction_id}/complete_request"
    end

    # Users

    def create_user email, password=nil, client_id=nil, scopes=nil
      password ||= SecureRandom.urlsafe_base64(12)
      options = {user: {email: email, password: password}}
      if client_id
        options[:client_id] = client_id
        raise Error.new("Invalid scopes parameter; must be an array") if !scopes.is_a?(Array)
        options[:scopes] = scopes.join(' ')
      end
      post '/users', options
    end

    # Prices

    def buy_price qty=1
      get '/prices/buy', {qty: qty}
    end

    def sell_price qty=1
      get '/prices/sell', {qty: qty}
    end

    def spot_price currency='USD'
      get '/prices/spot_rate', {currency: currency}
    end

    def exchange_rates
      get('/currencies/exchange_rates')
    end

    # Buys

    def buy! qty
      post '/buys', {qty: qty}
    end

    # Sells

    def sell! qty
      post '/sells', {qty: qty}
    end

    # Transfers

    def transfers page=1, options={}
      get '/transfers', {page: page}.merge(options)
    end

    # Wrappers for the main HTTP verbs

    def get(path, options={})
      http_verb :get, path, options
    end

    def post(path, options={})
      http_verb :post, path, options
    end

    def put(path, options={})
      http_verb :put, path, options
    end

    def delete(path, options={})
      http_verb :delete, path, options
    end

    def self.whitelisted_cert_store
      @@cert_store ||= build_whitelisted_cert_store
    end

    def self.build_whitelisted_cert_store
      path = File.expand_path(File.join(File.dirname(__FILE__), 'ca-coinbase.crt'))

      certs = [ [] ]
      File.readlines(path).each{|line|
        next if ["\n","#"].include?(line[0])
        certs.last << line
        certs << [] if line == "-----END CERTIFICATE-----\n"
      }

      result = OpenSSL::X509::Store.new

      certs.each{|lines|
        next if lines.empty?
        cert = OpenSSL::X509::Certificate.new(lines.join)
        result.add_cert(cert)
      }

      result
    end

    def ssl_options
      { verify: true, cert_store: self.class.whitelisted_cert_store }
    end

    def http_verb(verb, path, options={})

      nonce = options[:nonce] || (Time.now.to_f * 1e6).to_i

      if [:get, :delete].include? verb
        request_options = {}
        path = "#{path}?#{URI.encode_www_form(options)}" if !options.empty?
        hmac_message = nonce.to_s + @base_uri + path
      else
        request_options = {body: options.to_json}
        hmac_message = nonce.to_s + @base_uri + path + options.to_json
      end

      signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), @api_secret, hmac_message)

      headers = {
        'ACCESS_KEY' => @api_key,
        'ACCESS_SIGNATURE' => signature,
        'ACCESS_NONCE' => nonce.to_s,
        "Content-Type" => "application/json",
      }

      request_options[:headers] = headers

      r = self.class.send(verb, path, request_options.merge(ssl_options))

      hash = Hashie::Mash.new(JSON.parse(r.body))
      raise Error.new(hash.error) if hash.error
      raise Error.new(hash.errors.join(", ")) if hash.errors

      convert_date_objects(convert_money_objects(hash))
    end

    class Error < StandardError; end

    protected

    def convert_money_objects obj
      if obj.is_a?(Array)
        obj.map! { |o| convert_money_objects(o) }
      elsif obj.is_a?(Hash)
        if obj[:amount] && (obj[:currency] || obj[:currency_iso])
          obj = obj[:amount].to_money((obj[:currency] || obj[:currency_iso]))
        elsif obj[:cents] && (obj[:currency] || obj[:currency_iso])
          obj = Money.new(obj[:cents], (obj[:currency] || obj[:currency_iso]))
        else
          obj.each do |k,v|
            obj[k] = convert_money_objects(v)
          end
        end
      end
      obj
    end

    def convert_date_objects obj
      @@date_keys ||= ['created_at', 'payout_date', 'last_run', 'next_run']
      if obj.is_a?(Array)
        obj.map! { |o| convert_date_objects(o) }
      elsif obj.is_a?(Hash)
        obj.each do |k,v|
          if @@date_keys.include? k
            obj[k] = Time.parse(v) rescue nil
          else
            obj[k] = convert_date_objects(v)
          end
        end
      end
      obj
    end

  end
end

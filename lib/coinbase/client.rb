require 'httparty'
require 'multi_json'
require 'hashie'
require 'money'
require 'time'
require 'oauth2'

module Coinbase
  class Client
    include HTTParty
    ssl_ca_file File.expand_path(File.join(File.dirname(__FILE__), 'ca-coinbase.crt'))

    def initialize(api_key, options={})
      @api_key = api_key
      @is_oauth = options.delete(:is_oauth)

      if @is_oauth
        client_id = options[:oauth_client_id] || ENV['COINBASE_CLIENT_ID']
        client_secret = options[:oauth_client_secret] || ENV['COINBASE_CLIENT_SECRET']
        @oauth_client = OAuth2::Client.new(client_id, client_secret)
        @oauth_client.connection.url_prefix = options[:base_uri] || 'https://coinbase.com/api/v1'
        @oauth_token = OAuth2::AccessToken.new(@oauth_client, @api_key, {:refresh_token => options[:refresh_token]})
      else
        # defaults
        options[:base_uri] ||= 'https://coinbase.com/api/v1'
        options[:format]   ||= :json
        options.each do |k,v|
          self.class.send k, v
        end
      end

    end

    # Account

    def balance options={}
      h = get '/account/balance', options
      h['amount'].to_money(h['currency'])
    end

    def receive_address options={}
      get '/account/receive_address', options
    end

    def generate_receive_address options={}
      post '/account/generate_receive_address', options
    end

    # Buttons

    def create_button name, price, description=nil, custom=nil, options={}
      options[:button]                        ||= {}
      options[:button][:name]                 ||= name
      price = price.to_money unless price.is_a?(Money)
      options[:button][:price_string]         ||= price.to_f.to_s
      options[:button][:price_currency_iso]   ||= price.currency.iso_code
      options[:button][:description]          ||= description
      options[:button][:custom]               ||= custom
      r = post '/buttons', options
      if r.success?
        r.embed_html = "<div class=\"coinbase-button\" data-code=\"#{r.button.code}\"></div><script src=\"https://coinbase.com/assets/button.js\" type=\"text/javascript\"></script>"
      end
      r
    end

    # Transactions

    def transactions page=1
      r = get '/transactions', {page: page}
      r.transactions ||= []
      r.transactions.each do |t|
        if amt = t.transaction.amount
          t.transaction.amount = amt.amount.to_money(amt.currency)
        end
      end
      r
    end

    def send_money to, amount, notes=nil, options={}
      options[:transaction]                         ||= {}
      options[:transaction][:to]                    ||= to
      amount = amount.to_money unless amount.is_a?(Money)
      options[:transaction][:amount_string]         ||= amount.to_f.to_s
      options[:transaction][:amount_currency_iso]   ||= amount.currency.iso_code
      options[:transaction][:notes]                 ||= notes
      r = post '/transactions/send_money', options
      if amt = r.transaction.amount
        r.transaction.amount = amt.amount.to_money(amt.currency)
      end
      r
    end

    def request_money from, amount, notes=nil, options={}
      options[:transaction]                         ||= {}
      options[:transaction][:from]                  ||= from
      amount = amount.to_money unless amount.is_a?(Money)
      options[:transaction][:amount_string]         ||= amount.to_f.to_s
      options[:transaction][:amount_currency_iso]   ||= amount.currency.iso_code
      options[:transaction][:notes]                 ||= notes
      r = post '/transactions/request_money', options
      if amt = r.transaction.amount
        r.transaction.amount = amt.amount.to_money(amt.currency)
      end
      r
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

    def create_user email, password=nil
      password ||= Array.new(12){rand(36).to_s(36)}.join
      options = {user: {email: email, password: password}}
      post '/users', options
    end

    # Prices

    def buy_price qty=1
      r = get '/prices/buy', {qty: qty}
      r['amount'].to_money(r['currency'])
    end

    def sell_price qty=1
      r = get '/prices/sell', {qty: qty}
      r['amount'].to_money(r['currency'])
    end

    # Buys

    def buy! qty
      r = post '/buys', {qty: qty}
      r = convert_money_objects(r)
      r.transfer.payout_date = Time.parse(r.transfer.payout_date) rescue nil
      r
    end

    # Sells

    def sell! qty
      r = post '/sells', {qty: qty}
      r = convert_money_objects(r)
      r.transfer.payout_date = Time.parse(r.transfer.payout_date) rescue nil
      r
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

    def http_verb(verb, path, options={})
      if @is_oauth
        path[0] = '' # make path relative
        r = @oauth_token.request(verb, path, {body:options})
        json = r.body
      else
        r = self.class.send(verb, path, {body: merge_options(options)})
        json = r.body
      end

      hash = Hashie::Mash.new(JSON.parse(json))
      raise Error.new(hash.error) if hash.error
      raise Error.new(hash.errors.join(", ")) if hash.errors
      hash
    end

    def oauth_refresh!
      @oauth_token = @oauth_token.refresh!
    end

    class Error < StandardError; end

    private

    def convert_money_objects obj
      if obj.is_a?(Array)
        obj.each_with_index do |o, i|
          obj[i] = convert_money_objects(o)
        end
      elsif obj.is_a?(Hash)
        if obj[:amount] && (obj[:currency] || obj[:currency_iso])
          obj = obj[:amount].to_money((obj[:currency] || obj[:currency_iso]))
        else
          obj.each do |k,v|
            obj[k] = convert_money_objects(v)
          end
        end
      end
      obj
    end

    def merge_options options
      options.merge!({api_key: @api_key})
    end
  end
end

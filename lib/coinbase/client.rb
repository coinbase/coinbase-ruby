require 'httparty'
require 'multi_json'

module Coinbase
  class Client
    include HTTParty
    base_uri 'https://coinbase.com/api/v1'
    default_timeout 2
    format :json

    def initialize(api_key)
      @api_key = api_key
    end

    # Account

    def balance options={}
      get '/account/balance', options
    end

    def receive_address options={}
      get '/account/receive_address', options
    end

    def generate_receive_address options={}
      post '/account/generate_receive_address', options
    end

    # Buttons

    def generate_button options={}
      post '/buttons', options
    end

    # Transactions

    def transactions options={}
      get '/transactions', options
    end

    def send_money options={}
      post '/transactions/send_money', options
    end

    def request_money options={}
      post '/transactions/request_money', options
    end

    def resend_request options={}
      put '/transactions/resend_request', options
    end

    def delete_request options={}
      delete '/transactions/delete_request', options
    end

    def complete_request options={}
      put '/transactions/complete_request', options
    end

    # Users

    def create_user options={}
      post '/users', options
    end

    # Wrappers for the main HTTP verbs

    def get(path, options={})
      self.class.get(path, body: merge_options(options)).body
    end

    def post(path, options={})
      self.class.post(path, body: merge_options(options)).body
    end

    def put(path, options={})
      self.class.put(path, body: merge_options(options)).body
    end

    def delete(path, options={})
      self.class.delete(path, body: merge_options(options)).body
    end

    private

    def merge_options options
      options.merge!({api_key: @api_key})
    end
  end
end
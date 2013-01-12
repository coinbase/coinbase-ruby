require 'httparty'
require 'multi_json'

module Coinbase
  class Client
    include HTTParty
    base_uri 'https://coinbase.com/api/v1'
    default_timeout 2

    def initialize(api_key)
      @api_key = api_key
    end

    def balance options={}
      get '/account/balance', options
    end

    # wrappers for the main HTTP verbs

    def get(url, options={})
      merge_options(options)
      self.class.get(url, options)
    end

    def post(url, options={})
      merge_options(options)
      self.class.post(url, options)
    end

    def put(url, options={})
      merge_options(options)
      self.class.put(url, options)
    end

    def delete(url, options={})
      merge_options(options)
      self.class.delete(url, options)
    end

    private

    def merge_options options
      options.merge!({api_key: @api_key})
    end
  end
end
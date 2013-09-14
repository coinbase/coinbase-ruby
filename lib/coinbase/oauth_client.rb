require 'client'
require 'oauth2'

module Coinbase
  class OauthClient < Client
    def initialize api_key, options={}
      access_token = options.delete(:access_token)
      client = OAuth2::Client.new(ENV['COINBASE_KEY'], ENV['COINBASE_SECRET'])
      @oauth_token  = OAuth2::AccessToken.new(client, access_token)
      super(api_key, options)
    end

    def receive_address
      url = self.class.base_uri + '/account/receive_address'
      JSON.parse(@oauth_token.get(url).body)
    end

    def balance options={} 
      url = self.class.base_uri + '/account/balance'
      JSON.parse(@oauth_token.get(url).body)['amount'].to_money(h['currency'])
    end

    def generate_receive_address options={}
      url = self.class.base_uri + '/account/generate_receive_address'
      JSON.parse(@oauth_token.post(url).body)
    end
  end
end
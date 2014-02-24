require 'oauth2'

module Coinbase
  class OAuthClient < Client

    COINBASE_API_URL = 'https://coinbase.com/api/v1'

    def initialize(client_id, client_secret, access_token, options={})
      oauth_client = OAuth2::Client.new(client_id, client_secret)
      oauth_client.connection.url_prefix = options[:base_uri] || COINBASE_API_URL
      token_options = {
        :refresh_token => options[:refresh_token],
        :expires_at => options[:expires_at],
        :expires_in => options[:expires_in],
        :expires => options[:expires]
      }
      @oauth_token = OAuth2::AccessToken.new(oauth_client, access_token, token_options)
    end

    def http_verb(verb, path, options={})
      path = remove_leading_slash(path)
      request_options = {
        :mode => :header,
        :body => options
      }
      response = oauth_token.request(verb, path, request_options)

      hash = Hashie::Mash.new(JSON.parse(response.body))
      raise Error.new(hash.error) if hash.error
      raise Error.new(hash.errors.join(", ")) if hash.errors
      hash
    end

    # Getter included so it can be mocked out in testing.
    def oauth_token
      @oauth_token
    end

    def refresh_token
       @oauth_token = oauth_token.refresh!
    end

    def remove_leading_slash(path)
      path.sub(/^\//, '')
    end
  end
end

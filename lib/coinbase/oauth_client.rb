require 'oauth2'

module Coinbase
  class OAuthClient < Client

    COINBASE_API_URL = 'https://coinbase.com/api/v1'

    def initialize(client_id, client_secret, access_token=nil, options={})
      @oauth_client = OAuth2::Client.new(client_id, client_secret)
      @oauth_client.connection.url_prefix = options[:base_uri] || COINBASE_API_URL
      token_options = {
        :refresh_token => options[:refresh_token],
        :expires_at => options[:expires_at],
        :expires_in => options[:expires_in],
        :expires => options[:expires]
      }
      @oauth_token = OAuth2::AccessToken.new(@oauth_client, access_token, token_options) if access_token
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

    def oauth_token
      raise "Access token not initialized." unless @oauth_token
      @oauth_token
    end

    def refresh!
       @oauth_token = oauth_token.refresh!
    end

    def get_authorize_url(redirect_uri, options={})
      scope = options[:scope] ? options[:scope].join('+') : nil
      url = @oauth_client.auth_code.authorize_url(redirect_uri: redirect_uri, scope: scope)
      url = url + '&' + options[:params] if options[:params]
      url
    end

    def acquire_access_token(authorization_code, redirect_uri)
      @oauth_token = @oauth_client.auth_code.get_token(authorization_code, redirect_uri: redirect_uri)
    end

    private

    def remove_leading_slash(path)
      path.sub(/^\//, '')
    end
  end
end

require 'oauth2'

module Coinbase
  class OAuthClient < Client

    OAUTH_SITE     = 'https://coinbase.com'
    AUTHORIZE_PATH = '/oauth/authorize'
    TOKEN_PATH     = '/oauth/token'
    FIVE_MINUTES   = 300

    # Initializes a Coinbase Client using OAuth 2.0 credentials
    #
    # @param [String] client_id this application's Coinbase OAuth2 CLIENT_ID
    # @param [String] client_secret this application's Coinbase OAuth2 CLIENT_SECRET
    # @param [Hash] user_credentials OAuth 2.0 credentials to use
    # @option user_credentials [String] access_token Must pass either this or token
    # @option user_credentials [String] token Must pass either this or access_token
    # @option user_credentials [String] refresh_token Optional
    # @option user_credentials [Integer] expires_at Optional
    # @option user_credentials [Integer] expires_in Optional
    #
    # Please note access tokens will be automatically refreshed when expired
    # Use the credentials method when finished with the client to retrieve up-to-date credentials
    def initialize(client_id, client_secret, user_credentials, options={})
      if options[:sandbox]
        options[:site] = 'https://sandbox.coinbase.com'
        options[:base_uri] = 'https://api.sandbox.coinbase.com/v1'
      end
      site = options[:site] || OAUTH_SITE
      client_opts = {
        :site          => options[:base_uri] || BASE_URI,
        :authorize_url => options[:authorize_url] || "#{site}#{AUTHORIZE_PATH}",
        :token_url     => options[:token_url] || "#{site}#{TOKEN_PATH}",
        :ssl           => {
                            :verify => true,
                            :cert_store => ::Coinbase::Client.whitelisted_cert_store
                          },
        :raise_errors  => false
      }
      @oauth_client = OAuth2::Client.new(client_id, client_secret, client_opts)
      token_hash = user_credentials.dup
      token_hash[:access_token] ||= token_hash[:token]

      # Fudge expiry to avoid race conditions
      token_hash[:expires_in] = token_hash[:expires_in].to_i - FIVE_MINUTES if token_hash[:expires_in]
      token_hash[:expires_at] = token_hash[:expires_at].to_i - FIVE_MINUTES if token_hash[:expires_at]

      token_hash.delete :expires
      raise "No access token provided" unless token_hash[:access_token]
      @oauth_token = OAuth2::AccessToken.from_hash(@oauth_client, token_hash)
    end

    def http_verb(verb, path, options={})
      path = remove_leading_slash(path)

      if [:get, :delete].include? verb
        request_options = {params: options}
      else
        request_options = {headers: build_headers({"Content-Type" => "application/json"}, options), body: options.to_json}
      end
      response = oauth_token.request(verb, path, request_options)

      handle_response(response)
    end

    def refresh!
      raise "Access token not initialized." unless @oauth_token
      @oauth_token = @oauth_token.refresh!
    end

    def oauth_token
      raise "Access token not initialized." unless @oauth_token
      refresh! if @oauth_token.expired?
      @oauth_token
    end

    def credentials
      @oauth_token.to_hash
    end

    private

    def remove_leading_slash(path)
      path.sub(/^\//, '')
    end
  end
end

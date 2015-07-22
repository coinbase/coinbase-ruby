module Coinbase
  module Wallet
    BASE_API_URL  = "https://api.coinbase.com"
    API_VERSION   = '2015-06-16'

    class Client < NetHTTPClient
      def initialize(options={})
        [ :api_key, :api_secret ].each do |opt|
          raise unless options.has_key? opt
        end
        @api_key = options[:api_key]
        @api_secret = options[:api_secret]
        @api_uri = URI.parse(options[:api_url] || BASE_API_URL)
        super(@api_uri, options)
      end

      def auth_headers(method, path, body)
        ts = Time.now.to_i.to_s
        signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'),
                                            @api_secret,
                                            ts + method + path + body.to_s)
        { 'CB-ACCESS-KEY' => @api_key,
          'CB-ACCESS-SIGN' => signature,
          'CB-ACCESS-TIMESTAMP' => ts,
          'CB-VERSION' => API_VERSION }
      end
    end

    class OAuthClient < NetHTTPClient
      attr_accessor :access_token, :refresh_token

      def initialize(options={})
        raise unless options.has_key? :access_token
        @access_token = options[:access_token]
        @refresh_token = options[:refresh_token]
        @oauth_uri = URI.parse(options[:api_url] || BASE_API_URL)
        super(@oauth_uri, options)
      end

      def auth_headers(method, path, body)
        { 'Authorization' => "Bearer #{@access_token}",
          'CB-VERSION' => API_VERSION }
      end

      def authorize!(redirect_url, params = {})
        raise NotImplementedError
      end

      def revoke!(params = {})
        params[:token] ||= @access_token

        out = nil
        post("/oauth/revoke", params) do |resp|
          out = APIObject.new(self, resp.body)
          yield(out, resp) if block_given?
        end
        out
      end

      def refresh!(params = {})
        params[:grant_type] = 'refresh_token'
        params[:refresh_token] ||= @refresh_token

        raise "Missing Parameter: refresh_token" unless params.has_key?(:refresh_token)

        out = nil
        post("/oauth/token", params) do |resp|
          out = APIObject.new(self, resp.body)
          # Update tokens to current instance
          # Developer should always persist them
          @access_token = out.access_token
          @refresh_token = out.refresh_token
          yield(out, resp) if block_given?
        end
        out
      end
    end

    class AsyncClient < EMHTTPClient
      def initialize(options={})
        [ :api_key, :api_secret ].each do |opt|
          raise unless options.has_key? opt
        end
        @api_key = options[:api_key]
        @api_secret = options[:api_secret]
        @api_uri = URI.parse(options[:api_url] || BASE_API_URL)
      end

      def auth_headers(method, path, body)
        ts = Time.now.to_i.to_s
        signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'),
                                            @api_secret,
                                            ts + method + path + body.to_s)
        { 'CB-ACCESS-KEY' => @api_key,
          'CB-ACCESS-SIGN' => signature,
          'CB-ACCESS-TIMESTAMP' => ts,
          'CB-VERSION' => API_VERSION }
      end
    end
  end
end

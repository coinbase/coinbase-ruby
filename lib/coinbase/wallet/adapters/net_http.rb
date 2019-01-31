module Coinbase
  module Wallet
    # Net-HTTP adapter
    class NetHTTPClient < APIClient
      def initialize(base_uri, options = {})
        @conn = Net::HTTP.new(base_uri.host, base_uri.port)
        @conn.use_ssl = true if base_uri.scheme == 'https'
        @conn.cert_store = self.class.whitelisted_certificates
        @conn.ssl_version = :TLSv1_2
      end

      private

      def http_verb(method, path, body = nil, headers = {})
        case method
        when 'GET' then req = Net::HTTP::Get.new(path)
        when 'PUT' then req = Net::HTTP::Put.new(path)
        when 'POST' then req = Net::HTTP::Post.new(path)
        when 'DELETE' then req = Net::HTTP::Delete.new(path)
        else raise
        end

        req.body = body

        req['Content-Type'] = 'application/json'
        req['User-Agent'] = "coinbase/ruby/#{Coinbase::Wallet::VERSION}"
        auth_headers(method, path, body).each do |key, val|
          req[key] = val
        end
        headers.each do |key, val|
          req[key] = val
        end

        resp = @conn.request(req)
        out = NetHTTPResponse.new(resp)
        Coinbase::Wallet::check_response_status(out)
        yield(out)
        out.data
      end
    end

    # Net-Http response object
    class NetHTTPResponse < APIResponse
      def body
        JSON.parse(@response.body) rescue {}
      end

      def body=(body)
        @response.body = body.to_json
      end

      def data
        body['data']
      end

      def headers
        out = @response.to_hash.map do |key, val|
          [ key.upcase.gsub('_', '-'), val.count == 1 ? val.first : val ]
        end
        out.to_h
      end

      def status
        @response.code.to_i
      end
    end
  end
end

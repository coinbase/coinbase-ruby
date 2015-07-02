module Coinbase
  module Wallet
    # Response item abstract model
    class APIObject < Hash
      def initialize(client, data)
        super()
        update(data)
        @client = client
      end

      def refresh!(params = {})
        @client.get(self['resource_path'], params) do |resp|
          update(resp.data)
          yield(resp.data, resp) if block_given?
        end
      end

      def update(data)
        return if data.nil?
        data.each { |key, val| self[key] = val } if data.is_a?(Hash)
      end

      def format(key, val)
        return if val.nil?
        # Looks like a number or currency
        if val.class == Hash
          APIObject.new(@client, val)
        elsif key =~ /_at$/ && (Time.iso8601(val) rescue nil)
          Time.parse(val)
        elsif key == "amount" && val =~ /^.{0,1}\s*[0-9,]*\.{0,1}[0-9]*$/
          BigDecimal(val.gsub(/[^0-9\.]/, ''))
        else
          val
        end
      end

      def method_missing(method, *args, &blk)
        format(method.to_s, self[method.to_s]) || super
      end

      def respond_to_missing?(method, include_all = false)
        self.key?(method.to_s) || super
      end
    end
  end
end

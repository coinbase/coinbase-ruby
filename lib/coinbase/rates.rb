class Money
  module Bank
    class Coinbase < VariableExchange

      def initialize(coinbase=nil)
        @coinbase = coinbase || ::Coinbase::Client.new
        super()
      end

      # @return [Integer] Returns the Time To Live (TTL) in seconds.
      attr_reader :ttl_in_seconds

      # @return [Time] Returns the time when the rates expire.
      attr_reader :rates_expiration

      ##
      # Set the Time To Live (TTL) in seconds.
      #
      # @param [Integer] the seconds between an expiration and another.
      def ttl_in_seconds=(value)
        @ttl_in_seconds = value
        refresh_rates_expiration! if ttl_in_seconds
      end

      ##
      # Fetch fresh rates from Coinbase
      def fetch_rates!(opts={})
        store.transaction do
          @coinbase.exchange_rates.each do |k, v|
            matches = /(.*)_to_(.*)/.match(k)
            store.add_rate(matches[1], matches[2], v)
          end
        end
      end

      # Refreshes all the rates if they are expired.
      #
      # @return [Boolean]
      def expire_rates
        if @ttl_in_seconds && @rates_expiration <= Time.now
          fetch_rates!
          true
        else
          false
        end
      end

      def get_rate(from, to, opts = {})
        expire_rates
        store.get_rate(from, to)
      end

    private

      ##
      # Set the rates expiration TTL seconds from the current time.
      #
      # @return [Time] The next expiration.
      def refresh_rates_expiration!
        if @ttl_in_seconds
          @rates_expiration = Time.now + @ttl_in_seconds
        end
      end
    end
  end
end

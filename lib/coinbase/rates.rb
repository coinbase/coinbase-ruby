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
        fn = lambda do
          @rates = @coinbase.exchange_rates
          refresh_rates_expiration!
        end

        if opts[:without_mutex]
          fn.call
        else
          @mutex.synchronize { fn.call }
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
        super
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

      # Return the rate hashkey for the given currencies.
      #
      # @param [Currency, String, Symbol] from The currency to exchange from.
      # @param [Currency, String, Symbol] to The currency to exchange to.
      #
      # @return [String]
      #
      # @example
      #   rate_key_for("USD", "CAD") #=> "usd_to_cad"
      def rate_key_for(from, to)
        "#{::Money::Currency.wrap(from).iso_code}_to_#{::Money::Currency.wrap(to).iso_code}".downcase
      end

    end
  end
end

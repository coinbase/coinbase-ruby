module Coinbase::Util
  class CurrencyPairError < StandardError; end

  # An adaptar that allow converts a currency into
  # a currency pair to coenciede with multiple crypto currenices
  #
  # @param currency [String] the currency option inputed by the developer
  # @return [String] The properly formatted currency pair
  def self.determine_currency_pair(currency)
      return 'BTC-' + currency if half_pair?(currency)
      return 'BTC-USD' if currency.nil?
      return currency  if valid_pair?(currency)

      raise CurrencyPairError, "invalid currency param"
  end

  # verifies with regex that the pair is a proper
  # currency pair. Proper pairs are
  # 3 chars - 3 chars
  # ex) BTC-USD, BTC-CAD, ETH-BTC etc
  #
  # @param pair [String] the pair to be tested
  def self.valid_pair?(pair)
    pair.match(/[A-Z]{3}-[A-Z]{3}/)
  end

  # checks to see if dev only supplied half a currency pair
  # in such case, we will default to BTC-currency
  #
  # @param currency [String] the currency inputed by the developer
  def self.half_pair?(currency)
    currency.match(/[A-Z]{3}/)
  end
end

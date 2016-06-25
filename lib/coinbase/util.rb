module Coinbase::Util
  class CurrencyPairError < StandardError; end

  # An adaptar that allow converts a currency into
  # a currency pair to coenciede with multiple crypto currenices
  #
  # @param currency [String] the currency option inputed by the developer
  # @return [String] The properly formatted currency pair
  def self.determine_currency_pair(params)
      return 'BTC-USD' if (!params[:currency] && !params[:currency_pair])
      return 'BTC-' + params[:currency] if params[:currency]
      return params[:currency_pair]  if params[:currency_pair]

      raise CurrencyPairError, "invalid currency param"
  end
end

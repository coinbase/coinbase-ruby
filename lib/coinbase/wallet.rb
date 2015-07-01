require "coinbase/wallet/version"

require "base64"
require "bigdecimal"
require "json"
require "uri"
require "net/https"
require "em-http"

require "coinbase/wallet/api_errors"
require "coinbase/wallet/api_response"
require "coinbase/wallet/api_client"
require "coinbase/wallet/adapters/net_http.rb"
require "coinbase/wallet/adapters/em_http.rb"
require "coinbase/wallet/models/api_object"
require "coinbase/wallet/models/account"
require "coinbase/wallet/models/user"
require "coinbase/wallet/models/transaction"
require "coinbase/wallet/models/transfer"
require "coinbase/wallet/models/order"
require "coinbase/wallet/models/checkout"
require "coinbase/wallet/client"

module Coinbase
  module Wallet
  end
end

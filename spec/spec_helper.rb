require 'bundler/setup'
require 'webmock/rspec'
Bundler.setup

require 'coinbase/wallet'

def mock_item
  { 'key1' => 'val1', 'key2' => 'val2' }
end

def mock_collection
  [ mock_item, mock_item ]
end

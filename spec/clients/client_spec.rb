require 'spec_helper'
require 'timecop'

describe Coinbase::Wallet::Client do
  let(:client) { Coinbase::Wallet::Client.new(api_key: 'api_key', api_secret: 'api_secret') }

  it 'supplies correct headers' do
    time = Time.utc(2015, 7, 1, 0, 0, 0)
    timestamp = 1435708800

    stub_request(:get, 'https://api.coinbase.com/v2/user')
      .with('headers' => {
          'CB-ACCESS-KEY' => 'api_key',
          'CB-ACCESS-SIGN' => '9a413abc5a25a949932cd2b9963906d543f2df935c3a56159e24edb2095d78ee',
          'CB-ACCESS-TIMESTAMP' => timestamp.to_s,
          'CB-VERSION' => Coinbase::Wallet::API_VERSION,
        })
      .to_return(body: { data: mock_item }.to_json)

    stub_request(:post, 'https://api.coinbase.com/v2/accounts')
      .with('headers' => {
          'CB-ACCESS-KEY' => 'api_key',
          'CB-ACCESS-SIGN' => '3d4a73da32fc7fa55862865efd60c0cc994e5616d138a3c3b605a3ed504b235c',
          'CB-ACCESS-TIMESTAMP' => timestamp,
          'CB-VERSION' => Coinbase::Wallet::API_VERSION,
        })
      .to_return(body: { data: mock_item }.to_json)

    Timecop.freeze(time) do
      expect { client.current_user }.to_not raise_error
      expect { client.create_account(name: "new wallet") }.to_not raise_error
    end
  end
end
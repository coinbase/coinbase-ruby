require 'spec_helper'

describe Coinbase::Wallet::Order do
  before :all do
    @object_data = {
      'id' => '0fdfb26e-bd26-5e1c-b055-7b935e57fa33',
      'code' => '66BEOV2A',
      'status' => 'paid',
      'type' => 'order',
      'name' => 'Order #123',
      'description' => 'Sample order',
      'amount' => {
        'amount' => '10.00',
        'currency' => 'USD'
      },
      'payout_amount' => nil,
      'bitcoin_address' => 'mymZkiXhQNd6VWWG7VGSVdDX9bKmviti3U',
      'bitcoin_amount' => {
        'amount' => '1.00000000',
        'currency' => 'BTC'
      },
      'bitcoin_uri' => 'bitcoin:mrNo5ntJfWP8BGjR2MkAxEgoE8NDu4CM3g?amount=1.00&r=https://www.coinbase.com/r/555b9570a54d75860e00041d',
      'receipt_url' => 'https://www.coinbase.com/orders/d5d3e516dae19ca5b444fe56405ee917/receipt',
      'expires_at' => '2015-01-31T20:49:02Z',
      'mispaid_at' => nil,
      'paid_at' => '2015-01-31T20:49:02Z',
      'refund_address' => 'n3z9tkPHcMcUwGBbyjipT1RxJ3qXK4CKNQ',
      'transaction' => {
        'id' => 'aee1de26-9d08-56bf-8c51-7f8e6a23e046',
        'resource' => 'transaction'
      },
      'refunds' => [],
      'mispayments' => [],
      'metadata' => {},
      'created_at' => '2015-01-31T20:49:02Z',
      'updated_at' => '2015-01-31T20:49:02Z',
      'resource' => 'order',
      'resource_path' => '/v2/orders/0fdfb26e-bd26-5e1c-b055-7b935e57fa33'
    }

    @client = Coinbase::Wallet::Client.new(api_key: 'api_key', api_secret: 'api_secret')
    @object = Coinbase::Wallet::Order.new(@client, @object_data)
  end

  describe '#refund!' do
    it 'should refund an order' do
      stub_request(:post, 'https://api.coinbase.com' + @object_data['resource_path'] + '/refund')
        .to_return(body: { data: mock_item }.to_json)
      expect(@object.refund!).to eq mock_item
    end
  end
end

require 'spec_helper'

describe Coinbase::Wallet::Checkout do
  before :all do
    @object_data = {
      'id' => 'ffc93ba1-874d-5c55-853c-53c9c4814b1e',
      'embed_code' => 'af0b52802ad7b36806e307b2d294e3b4',
      'type' => 'order',
      'name' => 'My Checkout',
      'description' => nil,
      'amount' => {
        'amount' => '99.00000000',
        'currency' => 'BTC'
      },
      'style' => 'buy_now_large',
      'customer_defined_amount' => false,
      'amount_presets' => [],
      'success_url' => nil,
      'cancel_url' => nil,
      'info_url' => nil,
      'auto_redirect' => false,
      'collect_shipping_address' => false,
      'collect_email' => false,
      'collect_phone_number' => false,
      'collect_country' => false,
      'metadata' => {},
      'created_at' => '2015-01-31T20:49:02Z',
      'updated_at' => '2015-01-31T20:49:02Z',
      'resource' => 'checkout',
      'resource_path' => '/v2/checkouts/ffc93ba1-874d-5c55-853c-53c9c4814b1e'
    }

    @client = Coinbase::Wallet::Client.new(api_key: 'api_key', api_secret: 'api_secret')
    @object = Coinbase::Wallet::Checkout.new(@client, @object_data)
  end

  describe '#orders' do
    it 'should get latest order' do
      stub_request(:get, 'https://api.coinbase.com' + @object_data['resource_path'] + '/orders')
        .to_return(body: { data: [mock_item] }.to_json)
      expect(@object.orders).to eq [mock_item]
    end
  end

  describe '#create_order' do
    it 'should create a new order' do
      stub_request(:post, 'https://api.coinbase.com' + @object_data['resource_path'] + '/orders')
        .to_return(body: { data: mock_item }.to_json)
      expect(@object.create_order).to eq mock_item
    end
  end
end

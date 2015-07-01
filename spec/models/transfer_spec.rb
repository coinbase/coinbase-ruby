require 'spec_helper'

describe Coinbase::Wallet::Transfer do
  before :all do
    @object_data = {
      'id' => '67e0eaec-07d7-54c4-a72c-2e92826897df',
      'status' => 'pending',
      'payment_method' => {
        'id' => '83562370-3e5c-51db-87da-752af5ab9559',
        'resource' => 'payment_method'
      },
      'transaction' => {
        'id' => '441b9494-b3f0-5b98-b9b0-4d82c21c252a',
        'resource' => 'transaction'
      },
      'amount' => {
        'amount' => '1.00000000',
        'currency' => 'BTC'
      },
      'total' => {
        'amount' => '10.25',
        'currency' => 'USD'
      },
      'subtotal' => {
        'amount' => '10.10',
        'currency' => 'USD'
      },
      'created_at' => '2015-01-31T20:49:02Z',
      'updated_at' => '2015-01-31T20:49:02Z',
      'resource' => 'buy',
      'resource_path' => '/v2/accounts/2bbf394c-193b-5b2a-9155-3b4732659ede/buys/67e0eaec-07d7-54c4-a72c-2e92826897df',
      'committed' => false,
      'instant' => false,
      'fees' => [
        {
          'type' => 'coinbase',
          'amount' => {
            'amount' => '0.00',
            'currency' => 'USD'
          }
        },
        {
          'type' => 'bank',
          'amount' => {
            'amount' => '0.15',
            'currency' => 'USD'
          }
        }
      ],
      'payout_at' => '2015-02-18T16 =>54 =>00-08 =>00'
    }

    @client = Coinbase::Wallet::Client.new(api_key: 'api_key', api_secret: 'api_secret')
    @object = Coinbase::Wallet::Transfer.new(@client, @object_data)
  end

  describe '#commit!' do
    it 'should commit an transfer (buy/sell/deposit/withdrawal)' do
      stub_request(:post, 'https://api.coinbase.com' + @object_data['resource_path'] + '/commit')
        .to_return(body: { data: mock_item }.to_json)
      expect(@object.commit!).to eq mock_item
    end
  end
end

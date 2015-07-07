require 'spec_helper'

describe Coinbase::Wallet::Address do
  before :all do
    @object_data = {
      'id' => 'dd3183eb-af1d-5f5d-a90d-cbff946435ff',
      'address' => 'mswUGcPHp1YnkLCgF1TtoryqSc5E9Q8xFa',
      'name' => 'One off payment',
      'created_at' => '2015-01-31T20:49:02Z',
      'updated_at' => '2015-03-31T17:25:29-07:00',
      'resource' => 'address',
      'resource_path' => '/v2/accounts/2bbf394c-193b-5b2a-9155-3b4732659ede/addresses/dd3183eb-af1d-5f5d-a90d-cbff946435ff'
    }

    @client = Coinbase::Wallet::Client.new(api_key: 'api_key', api_secret: 'api_secret')
    @object = Coinbase::Wallet::Address.new(@client, @object_data)
  end

  describe '#transactions' do
    it 'should get latest transactions for address' do
      stub_request(:get, 'https://api.coinbase.com' + @object_data['resource_path'] + '/transactions')
        .to_return(body: { data: [mock_item] }.to_json)
      expect(@object.transactions).to eq [mock_item]
    end
  end
end

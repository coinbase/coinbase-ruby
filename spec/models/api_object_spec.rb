require 'spec_helper'

describe Coinbase::Wallet::APIObject do
  before :all do
    @object_data = {
      'id' => '2bbf394c-193b-5b2a-9155-3b4732659ede',
      'name' => 'My Wallet',
      'primary' => true,
      'type' => 'wallet',
      'currency' => 'BTC',
      'balance' => {
        'amount' => '39.59000000',
        'currency' => 'BTC'
      },
      'native_balance' => {
        'amount' => '395.90',
        'currency' => 'USD'
      },
      'created_at' => '2015-01-31T20:49:02Z',
      'updated_at' => '2015-01-31T20:49:02Z',
      'resource' => 'account',
      'resource_path' => '/v2/accounts/2bbf394c-193b-5b2a-9155-3b4732659ede'
    }

    @client = Coinbase::Wallet::Client.new(api_key: 'api_key', api_secret: 'api_secret')
    @object = Coinbase::Wallet::APIObject.new(@client, @object_data)
  end

  it 'should access attributes' do
    expect(@object.id).to eq @object_data['id']
    expect(@object.balance.currency).to eq @object_data['balance']['currency']
    expect(@object.primary).to eq @object_data['primary']
  end

  it 'should convert hashes to APIObjects' do
    expect(@object.balance.class).to eq Coinbase::Wallet::APIObject
  end

  it 'should convert amounts to BigDecimal' do
    expect(@object.balance.amount.class).to eq BigDecimal
    expect(@object.native_balance.amount.to_f).to eq 395.90
  end

  it 'should convert timestamps to Time' do
    expect(@object.created_at.class).to eq Time
  end

  describe '#update' do
    it 'should update object' do
      @object.update({'id' => '1234'})
      expect(@object.id).to eq '1234'
    end
  end

  describe '#refresh!' do
    it 'should fetch new data for object' do
      stub_request(:get, 'https://api.coinbase.com' + @object_data['resource_path'])
        .to_return(body: { data: { id: 'new_id' } }.to_json)
      @object.refresh!
      expect(@object.id).to eq 'new_id'
    end
  end
end

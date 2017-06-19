require 'spec_helper'

describe Coinbase::Wallet::Account do
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
    @object = Coinbase::Wallet::Account.new(@client, @object_data)
  end

  it "updates itself" do
    ret = @object_data.clone
    ret['name'] = 'new name'
    stub_request(:put, /#{@object.resource_path}/)
      .to_return(body: { data: ret }.to_json)
    @object.update!(name: "new name")
    expect(@object.name).to eq "new name"
  end

  it "makes itself primary" do
    stub_request(:post, /#{@object.resource_path}\/primary/)
      .to_return(body: { data: mock_item }.to_json)
    expect(@object.make_primary!).to eq mock_item
  end

  it "deletes itself" do
    stub_request(:delete, /#{@object.resource_path}/)
      .to_return(body: { data: mock_item }.to_json)
    expect(@object.delete!).to eq mock_item
  end

  it "gets addresses" do
    stub_request(:get, /#{@object.resource_path}\/addresses/)
      .to_return(body: { data: mock_collection }.to_json)
    expect(@object.addresses).to eq mock_collection
  end

  it "gets address" do
    stub_request(:get, /#{@object.resource_path}\/addresses\/test/)
      .to_return(body: { data: mock_item }.to_json)
    expect(@object.address("test")).to eq mock_item
  end

  it "gets address transactions" do
    stub_request(:get, /#{@object.resource_path}\/addresses\/test\/transactions/)
      .to_return(body: { data: mock_collection }.to_json)
    expect(@object.address_transactions("test")).to eq mock_collection
  end

  it "creates address" do
    stub_request(:post, /#{@object.resource_path}\/addresses/)
      .to_return(body: { data: mock_item }.to_json)
    expect(@object.create_address).to eq mock_item
  end

  it "gets transactions" do
    stub_request(:get, /#{@object.resource_path}\/transactions/)
      .to_return(body: { data: mock_collection }.to_json)
    expect(@object.transactions).to eq mock_collection
  end

  it "gets transaction" do
    stub_request(:get, /#{@object.resource_path}\/transactions\/test/)
      .to_return(body: { data: mock_item }.to_json)
    expect(@object.transaction('test')).to eq mock_item
  end

  it "sends money" do
    stub_request(:post, /#{@object.resource_path}\/transactions/)
      .to_return(body: { data: mock_item }.to_json)
    expect(@object.send(amount: 10, to: 'example@coinbase.com')).to eq mock_item
  end
  
  it "transfers money" do
    stub_request(:post, /#{@object.resource_path}\/transactions/)
      .to_return(body: { data: mock_item }.to_json)
    expect(@object.transfer(amount: 10, to: 'example@coinbase.com')).to eq mock_item
  end
  
  it "requests money" do
    stub_request(:post, /#{@object.resource_path}\/transactions/)
      .to_return(body: { data: mock_item }.to_json)
    expect(@object.request(amount: 10, currency: "BTC", to: 'example@coinbase.com')).to eq mock_item
  end

  it "gets buys" do
    stub_request(:get, /#{@object.resource_path}\/buys/)
      .to_return(body: { data: mock_collection }.to_json)
    expect(@object.list_buys).to eq mock_collection
  end

  it "gets buy" do
    stub_request(:get, /#{@object.resource_path}\/buys\/test/)
      .to_return(body: { data: mock_item }.to_json)
    expect(@object.list_buy('test')).to eq mock_item
  end

  it "buys bitcoin" do
    stub_request(:post, /#{@object.resource_path}\/buys/)
      .to_return(body: { data: mock_item }.to_json)
    expect(@object.buy(amount: 10, currency: 'BTC')).to eq mock_item
  end

  it "commits buy" do
    stub_request(:post, /#{@object.resource_path}\/buys\/test\/commit/)
      .to_return(body: { data: mock_item }.to_json)
    expect(@object.commit_buy("test")).to eq mock_item
  end

  it "gets sells" do
    stub_request(:get, /#{@object.resource_path}\/sells/)
      .to_return(body: { data: mock_collection }.to_json)
    expect(@object.list_sells).to eq mock_collection
  end

  it "gets sell" do
    stub_request(:get, /#{@object.resource_path}\/sells\/test/)
      .to_return(body: { data: mock_item }.to_json)
    expect(@object.list_sell('test')).to eq mock_item
  end

  it "sells bitcoin" do
    stub_request(:post, /#{@object.resource_path}\/sells/)
      .to_return(body: { data: mock_item }.to_json)
    expect(@object.sell(amount: 10, currency: 'BTC')).to eq mock_item
  end

  it "commits sell" do
    stub_request(:post, /#{@object.resource_path}\/sells\/test\/commit/)
      .to_return(body: { data: mock_item }.to_json)
    expect(@object.commit_sell("test")).to eq mock_item
  end

  it "gets deposits" do
    stub_request(:get, /#{@object.resource_path}\/deposits/)
      .to_return(body: { data: mock_collection }.to_json)
    expect(@object.list_deposits).to eq mock_collection
  end

  it "gets deposit" do
    stub_request(:get, /#{@object.resource_path}\/deposits\/test/)
      .to_return(body: { data: mock_item }.to_json)
    expect(@object.list_deposit('test')).to eq mock_item
  end

  it "deposits bitcoin" do
    stub_request(:post, /#{@object.resource_path}\/deposits/)
      .to_return(body: { data: mock_item }.to_json)
    expect(@object.deposit(amount: 10, currency: 'BTC')).to eq mock_item
  end

  it "commits deposit" do
    stub_request(:post, /#{@object.resource_path}\/deposits\/test\/commit/)
      .to_return(body: { data: mock_item }.to_json)
    expect(@object.commit_deposit("test")).to eq mock_item
  end

  it "gets withdrawals" do
    stub_request(:get, /#{@object.resource_path}\/withdrawals/)
      .to_return(body: { data: mock_collection }.to_json)
    expect(@object.list_withdrawals).to eq mock_collection
  end

  it "gets withdrawal" do
    stub_request(:get, /#{@object.resource_path}\/withdrawals\/test/)
      .to_return(body: { data: mock_item }.to_json)
    expect(@object.list_withdrawal('test')).to eq mock_item
  end

  it "withdrawals bitcoin" do
    stub_request(:post, /#{@object.resource_path}\/withdrawals/)
      .to_return(body: { data: mock_item }.to_json)
    expect(@object.withdraw(amount: 10, currency: 'BTC')).to eq mock_item
  end

  it "commits withdrawal" do
    stub_request(:post, /#{@object.resource_path}\/withdrawals\/test\/commit/)
      .to_return(body: { data: mock_item }.to_json)
    expect(@object.commit_withdrawal("test")).to eq mock_item
  end
end

require 'spec_helper'

describe Coinbase::Wallet do
  before :all do
    @client = Coinbase::Wallet::Client.new(api_key: 'api_key', api_secret: 'api_secret')
  end

  #
  # Data API
  #
  it "gets currencies" do
    stub_request(:get, "https://api.coinbase.com/v2/currencies")
      .to_return(body: { data: mock_collection }.to_json)
    expect(@client.currencies).to eq mock_collection
  end

  it "gets exchange rates" do
    stub_request(:get, "https://api.coinbase.com/v2/exchange-rates")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.exchange_rates).to eq mock_item
  end

  it "gets buy price" do
    stub_request(:get, "https://api.coinbase.com/v2/prices/BTC-USD/buy")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.buy_price).to eq mock_item
  end

  it "gets sell price" do
    stub_request(:get, "https://api.coinbase.com/v2/prices/BTC-USD/sell")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.sell_price).to eq mock_item
  end

  it "gets spot price" do
    stub_request(:get, "https://api.coinbase.com/v2/prices/BTC-USD/spot")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.spot_price).to eq mock_item
  end

  it "gets time" do
    stub_request(:get, "https://api.coinbase.com/v2/time")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.time).to eq mock_item
  end

  #
  # Wallet API
  #
  it "gets user" do
    stub_request(:get, "https://api.coinbase.com/v2/users/test")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.user('test')).to eq mock_item
  end

  it "gets current user" do
    stub_request(:get, "https://api.coinbase.com/v2/user")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.current_user).to eq mock_item
  end

  it "gets authorization info" do
    stub_request(:get, "https://api.coinbase.com/v2/user/auth")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.auth_info).to eq mock_item
  end

  it "updates current user" do
    stub_request(:put, "https://api.coinbase.com/v2/user")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.update_current_user(name: "test")).to eq mock_item
  end

  it "gets accounts" do
    stub_request(:get, "https://api.coinbase.com/v2/accounts")
      .to_return(body: { data: mock_collection }.to_json)
    expect(@client.accounts).to eq mock_collection
  end

  it "gets account" do
    stub_request(:get, "https://api.coinbase.com/v2/accounts/test")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.account("test")).to eq mock_item
  end

  it "gets account" do
    stub_request(:get, "https://api.coinbase.com/v2/accounts/primary")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.primary_account).to eq mock_item
  end

  it "creates account" do
    stub_request(:post, "https://api.coinbase.com/v2/accounts")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.create_account).to eq mock_item
  end

  it "changes primary account" do
    stub_request(:post, "https://api.coinbase.com/v2/accounts/test/primary")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.set_primary_account("test")).to eq mock_item
  end

  it "updates accounts" do
    stub_request(:put, "https://api.coinbase.com/v2/accounts/test")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.update_account("test", name: "new name")).to eq mock_item
  end

  it "deletes accounts" do
    stub_request(:delete, "https://api.coinbase.com/v2/accounts/test")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.delete_account("test")).to eq mock_item
  end

  it "gets addresses" do
    stub_request(:get, "https://api.coinbase.com/v2/accounts/test/addresses")
      .to_return(body: { data: mock_collection }.to_json)
    expect(@client.addresses("test")).to eq mock_collection
  end

  it "gets address" do
    stub_request(:get, "https://api.coinbase.com/v2/accounts/test1/addresses/test2")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.address("test1", "test2")).to eq mock_item
  end

  it "gets address transactions" do
    stub_request(:get, "https://api.coinbase.com/v2/accounts/test1/addresses/test2/transactions")
      .to_return(body: { data: mock_collection }.to_json)
    expect(@client.address_transactions("test1", "test2")).to eq mock_collection
  end

  it "creates address" do
    stub_request(:post, "https://api.coinbase.com/v2/accounts/test1/addresses")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.create_address("test1")).to eq mock_item
  end

  it "gets transactions" do
    stub_request(:get, "https://api.coinbase.com/v2/accounts/test/transactions")
      .to_return(body: { data: mock_collection }.to_json)
    expect(@client.transactions("test")).to eq mock_collection
  end

  it "gets transaction" do
    stub_request(:get, "https://api.coinbase.com/v2/accounts/test1/transactions/test2")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.transaction("test1", "test2")).to eq mock_item
  end

  it "sends money" do
    stub_request(:post, "https://api.coinbase.com/v2/accounts/test/transactions")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.send("test", amount: 10, to: 'example@coinbase.com')).to eq mock_item
  end

  it "transfers money" do
    stub_request(:post, "https://api.coinbase.com/v2/accounts/test/transactions")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.transfer("test", amount: 10, to: 'example@coinbase.com')).to eq mock_item
  end

  it "requests money" do
    stub_request(:post, "https://api.coinbase.com/v2/accounts/test/transactions")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.request("test", amount: 10, currency: 'BTC', to: 'example@coinbase.com')).to eq mock_item
  end

  it "completes request" do
    stub_request(:post, "https://api.coinbase.com/v2/accounts/test1/transactions/test2/complete")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.complete_request("test1", "test2")).to eq mock_item
  end

  it "re-sends request" do
    stub_request(:post, "https://api.coinbase.com/v2/accounts/test1/transactions/test2/resend")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.resend_request("test1", "test2")).to eq mock_item
  end

  it "cancels request" do
    stub_request(:delete, "https://api.coinbase.com/v2/accounts/test1/transactions/test2")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.cancel_request("test1", "test2")).to eq mock_item
  end

  it "lists buys" do
    stub_request(:get, "https://api.coinbase.com/v2/accounts/test/buys")
      .to_return(body: { data: mock_collection }.to_json)
    expect(@client.list_buys("test")).to eq mock_collection
  end

  it "lists buy" do
    stub_request(:get, "https://api.coinbase.com/v2/accounts/test1/buys/test2")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.list_buy("test1", "test2")).to eq mock_item
  end

  it "buys bitcoin" do
    stub_request(:post, "https://api.coinbase.com/v2/accounts/test/buys")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.buy("test", amount: 10, currency: 'BTC')).to eq mock_item
  end

  it "commits buy" do
    stub_request(:post, "https://api.coinbase.com/v2/accounts/test1/buys/test2/commit")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.commit_buy("test1", "test2")).to eq mock_item
  end

  it "lists sells" do
    stub_request(:get, "https://api.coinbase.com/v2/accounts/test/sells")
      .to_return(body: { data: mock_collection }.to_json)
    expect(@client.list_sells("test")).to eq mock_collection
  end

  it "lists sell" do
    stub_request(:get, "https://api.coinbase.com/v2/accounts/test1/sells/test2")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.list_sell("test1", "test2")).to eq mock_item
  end

  it "sells bitcoin" do
    stub_request(:post, "https://api.coinbase.com/v2/accounts/test/sells")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.sell("test", amount: 10, currency: 'BTC')).to eq mock_item
  end

  it "commits sell" do
    stub_request(:post, "https://api.coinbase.com/v2/accounts/test1/sells/test2/commit")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.commit_sell("test1", "test2")).to eq mock_item
  end

  it "lists deposits" do
    stub_request(:get, "https://api.coinbase.com/v2/accounts/test/deposits")
      .to_return(body: { data: mock_collection }.to_json)
    expect(@client.list_deposits("test")).to eq mock_collection
  end

  it "lists deposit" do
    stub_request(:get, "https://api.coinbase.com/v2/accounts/test1/deposits/test2")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.list_deposit("test1", "test2")).to eq mock_item
  end

  it "deposits bitcoin" do
    stub_request(:post, "https://api.coinbase.com/v2/accounts/test/deposits")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.deposit("test", amount: 10, currency: 'BTC')).to eq mock_item
  end

  it "commits deposit" do
    stub_request(:post, "https://api.coinbase.com/v2/accounts/test1/deposits/test2/commit")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.commit_deposit("test1", "test2")).to eq mock_item
  end

  it "lists withdrawals" do
    stub_request(:get, "https://api.coinbase.com/v2/accounts/test/withdrawals")
      .to_return(body: { data: mock_collection }.to_json)
    expect(@client.list_withdrawals("test")).to eq mock_collection
  end

  it "lists withdrawal" do
    stub_request(:get, "https://api.coinbase.com/v2/accounts/test1/withdrawals/test2")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.list_withdrawal("test1", "test2")).to eq mock_item
  end

  it "withdrawals bitcoin" do
    stub_request(:post, "https://api.coinbase.com/v2/accounts/test/withdrawals")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.withdraw("test", amount: 10, currency: 'BTC')).to eq mock_item
  end

  it "commits withdrawal" do
    stub_request(:post, "https://api.coinbase.com/v2/accounts/test1/withdrawals/test2/commit")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.commit_withdrawal("test1", "test2")).to eq mock_item
  end

  it "gets payment methods" do
    stub_request(:get, "https://api.coinbase.com/v2/payment-methods")
      .to_return(body: { data: mock_collection }.to_json)
    expect(@client.payment_methods).to eq mock_collection
  end

  #
  # Merchant API
  #
  it "gets merchant" do
    stub_request(:get, "https://api.coinbase.com/v2/merchants/test")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.merchant('test')).to eq mock_item
  end

  it "gets merchant orders" do
    stub_request(:get, "https://api.coinbase.com/v2/orders")
      .to_return(body: { data: mock_collection }.to_json)
    expect(@client.orders).to eq mock_collection
  end

  it "gets merchant order" do
    stub_request(:get, "https://api.coinbase.com/v2/orders/test")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.order("test")).to eq mock_item
  end

  it "creates an order" do
    stub_request(:post, "https://api.coinbase.com/v2/orders")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.create_order(name: "test", amount: 10, currency: "BTC")).to eq mock_item
  end

  it "refunds merchant order" do
    stub_request(:post, "https://api.coinbase.com/v2/orders/test/refund")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.refund_order("test", currency: "BTC")).to eq mock_item
  end

  it "gets checkouts" do
    stub_request(:get, "https://api.coinbase.com/v2/checkouts")
      .to_return(body: { data: mock_collection }.to_json)
    expect(@client.checkouts).to eq mock_collection
  end

  it "gets checkout" do
    stub_request(:get, "https://api.coinbase.com/v2/checkouts/test")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.checkout("test")).to eq mock_item
  end

  it "creates checkout" do
    stub_request(:post, "https://api.coinbase.com/v2/checkouts")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.create_checkout(name: "test", amount: 10, currency: "BTC")).to eq mock_item
  end

  it "gets checkout orders" do
    stub_request(:get, "https://api.coinbase.com/v2/checkouts/test/orders")
      .to_return(body: { data: mock_collection }.to_json)
    expect(@client.checkout_orders("test")).to eq mock_collection
  end

  it "creates checkout order" do
    stub_request(:post, "https://api.coinbase.com/v2/checkouts/test/orders")
      .to_return(body: { data: mock_item }.to_json)
    expect(@client.create_checkout_order("test")).to eq mock_item
  end
end

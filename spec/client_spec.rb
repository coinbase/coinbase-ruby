require 'spec_helper'
require 'fakeweb'
require 'coinbase'

describe Coinbase::Client do
  BASE_URI = 'http://fake.com/api/v1' # switching to http (instead of https) seems to help FakeWeb

  before :all do
    @c = Coinbase::Client.new 'api key', 'api secret', {base_uri: BASE_URI}
    FakeWeb.allow_net_connect = false
  end

  # Auth and Errors

  it "raise errors" do
    fake :get, '/account/balance', {error: "some error"}
    expect{ @c.balance }.to raise_error(Coinbase::Client::Error, 'some error')
    fake :get, '/account/balance', {errors: ["some", "error"]}
    expect{ @c.balance }.to raise_error(Coinbase::Client::Error, 'some, error')
  end

  # Account

  it "should get balance" do
    fake :get, '/account/balance', {amount: "50.00000000", currency: 'BTC'}
    @c.balance.should == 50.to_money('BTC')
  end

  it "should get a receive address" do
    fake :get, '/account/receive_address', {address: "muVu2JZo8PbewBHRp6bpqFvVD87qvqEHWA", callback_url: nil}
    a = @c.receive_address
    a.address.should == "muVu2JZo8PbewBHRp6bpqFvVD87qvqEHWA"
    a.callback_url.should == nil
  end

  it "should generate new receive addresses" do
    fake :post, '/account/generate_receive_address', {address: "mmxJyTdxHUJUDoptwLHAGxLEd1rAxDJ7EV", callback_url: "http://example.com/callback"}
    a = @c.generate_receive_address
    a.address.should == "mmxJyTdxHUJUDoptwLHAGxLEd1rAxDJ7EV"
    a.callback_url.should == "http://example.com/callback"
  end

  it "should list accounts" do
    accounts_response = <<-eos
      {
        "accounts": [
          {
            "id": "536a541fa9393bb3c7000023",
            "name": "My Wallet",
            "balance": {
              "amount": "50.00000000",
              "currency": "BTC"
            },
            "native_balance": {
              "amount": "500.12",
              "currency": "USD"
            },
            "created_at": "2014-05-07T08:41:19-07:00",
            "primary": true,
            "active": true
          },
          {
            "id": "536a541fa9393bb3c7000034",
            "name": "Savings",
            "balance": {
              "amount": "0.00000000",
              "currency": "BTC"
            },
            "native_balance": {
              "amount": "0.00",
              "currency": "USD"
            },
            "created_at": "2014-05-07T08:50:10-07:00",
            "primary": false,
            "active": true
          }
        ],
        "total_count": 2,
        "num_pages": 1,
        "current_page": 1
      }
    eos

    fake :get, '/accounts', JSON.parse(accounts_response)
    r = @c.accounts
    r.total_count.should == 2
    primary_account = r.accounts.select { |acct| acct.primary }.first
    primary_account.id.should == "536a541fa9393bb3c7000023"
    primary_account.balance.should == 50.to_money("BTC")

    # Make sure paging works
    fake :get, '/accounts?page=2', JSON.parse(accounts_response)
    r = @c.accounts :page => 2
    FakeWeb.last_request.path.should include("page=2")
  end

  # Buttons

  it "should create a new button" do
    response = {:success=>true, :button=>{:code=>"93865b9cae83706ae59220c013bc0afd", :type=>"buy_now", :style=>"custom_large", :text=>"Pay With Bitcoin", :name=>"Order 123", :description=>"Sample description", :custom=>"Order123", :price=>{:cents=>123, :currency_iso=>"BTC"}}}
    fake :post, '/buttons', response
    r = @c.create_button "Order 123", 1.23, "Sample description"

    # Ensure BTC is assumed to be the default currency
    post_params = JSON.parse(FakeWeb.last_request.body)
    post_params['button']['price_currency_iso'].should == "BTC"
    post_params['button']['price_string'].should == "1.23000000"

    r.success?.should == true
    r.button.name.should == "Order 123"
    r.embed_html.should == %[<div class="coinbase-button" data-code="93865b9cae83706ae59220c013bc0afd"></div><script src="https://coinbase.com/assets/button.js" type="text/javascript"></script>]

    r = @c.create_button "Order 123", 1.23, "Sample description", nil, button_mode: 'page'
    r.success?.should == true
    r.button.name.should == "Order 123"
    r.embed_html.should == %[<a href="https://coinbase.com/checkouts/93865b9cae83706ae59220c013bc0afd" target="_blank"><img alt="Pay With Bitcoin" src="https://coinbase.com/assets/buttons/custom_large.png"></a>]

    r = @c.create_button "Order 123", 1.23, "Sample description", nil, button_mode: 'iframe'
    r.success?.should == true
    r.button.name.should == "Order 123"
    r.embed_html.should == %[<iframe src="https://coinbase.com/inline_payments/93865b9cae83706ae59220c013bc0afd" style="width:500px;height:160px;border:none;box-shadow:0 1px 3px rgba(0,0,0,0.25);overflow:hidden;" scrolling="no" allowtransparency="true" frameborder="0"></iframe>]
  end

  it "should create a new button with price in USD" do
    response = {:success=>true, :button=>{:code=>"93865b9cae83706ae59220c013bc0afd", :type=>"buy_now", :style=>"custom_large", :text=>"Pay With Bitcoin", :name=>"Order 123", :description=>"Sample description", :custom=>"Order123", :price=>{:cents=>123, :currency_iso=>"USD"}}}
    fake :post, '/buttons', response
    r = @c.create_button "Order 123", 1.23.to_money("USD"), "Sample description"

    post_params = JSON.parse(FakeWeb.last_request.body)
    post_params['button']['price_currency_iso'].should == "USD"
    post_params['button']['price_string'].should == "1.23"

    r.success?.should == true
    r.button.name.should == "Order 123"
    r.embed_html.should == %[<div class="coinbase-button" data-code="93865b9cae83706ae59220c013bc0afd"></div><script src="https://coinbase.com/assets/button.js" type="text/javascript"></script>]
  end

  it "should create order for the button" do
    response = {"success"=>true, "order"=>{"id"=>"UAHXEK24", "created_at"=>"2013-12-13T01:15:56-08:00", "status"=>"new", "total_btc"=>{"cents"=>123, "currency_iso"=>"BTC"}, "total_native"=>{"cents"=>123, "currency_iso"=>"BTC"}, "custom"=>"Order123", "receive_address"=>"1EWxf61QGAkQDNUDq6XynH2PdFRyZUm111", "button"=>{"type"=>"buy_now", "name"=>"Order 123", "description"=>"Sample description", "id"=>"93865b9cae83706ae59220c013bc0afd"}, "transaction"=>nil}}
    fake :post, '/buttons/93865b9cae83706ae59220c013bc0afd/create_order', response
    r = @c.create_order_for_button "93865b9cae83706ae59220c013bc0afd"
    r.order.button.id.should == "93865b9cae83706ae59220c013bc0afd"
    r.order.status.should == "new"
  end

  # Transactions

  it "should get transaction list" do
    response = {"current_user"=>{"id"=>"5011f33df8182b142400000e", "email"=>"user2@example.com", "name"=>"user2@example.com"}, "balance"=>{"amount"=>"50.00000000", "currency"=>"BTC"}, "total_count"=>2, "num_pages"=>1, "current_page"=>1, "transactions"=>[{"transaction"=>{"id"=>"5018f833f8182b129c00002f", "created_at"=>"2012-08-01T02:34:43-07:00", "amount"=>{"amount"=>"-1.10000000", "currency"=>"BTC"}, "request"=>true, "status"=>"pending", "sender"=>{"id"=>"5011f33df8182b142400000e", "name"=>"User Two", "email"=>"user2@example.com"}, "recipient"=>{"id"=>"5011f33df8182b142400000a", "name"=>"User One", "email"=>"user1@example.com"}}}, {"transaction"=>{"id"=>"5018f833f8182b129c00002e", "created_at"=>"2012-08-01T02:36:43-07:00", "hsh" => "9d6a7d1112c3db9de5315b421a5153d71413f5f752aff75bf504b77df4e646a3", "amount"=>{"amount"=>"-1.00000000", "currency"=>"BTC"}, "request"=>false, "status"=>"complete", "sender"=>{"id"=>"5011f33df8182b142400000e", "name"=>"User Two", "email"=>"user2@example.com"}, "recipient_address"=>"37muSN5ZrukVTvyVh3mT5Zc5ew9L9CBare"}}]}
    fake :get, '/transactions?page=1', response
    r = @c.transactions
    r.transactions.first.transaction.id.should == '5018f833f8182b129c00002f'
    r.transactions.last.transaction.hsh.should == '9d6a7d1112c3db9de5315b421a5153d71413f5f752aff75bf504b77df4e646a3'
    r.transactions.first.transaction.amount.should == "-1.1".to_money("BTC")
  end

  it "should get transaction detail" do
    response = {"transaction"=>{"id"=>"5011f33df8182b142400000e", "created_at"=>"2013-12-19T05:20:15-08:00", "hsh"=>"ff11a892bc6f7c345a5d74d52b0878f6a7e5011f33df8182b142400000e", "amount"=>{"amount"=>"-0.01000000", "currency"=>"BTC"}, "request"=>false, "status"=>"pending", "sender"=>{"id"=>"5011f33df8182b142400000e", "email"=>"tuser2@example.com", "name"=>"User Two"}, "recipient_address"=>"1EWxf61QGAkQDNUDq6XynH2PdFRyZUm111", "notes"=>""}}
    fake :get, "/transactions/5011f33df8182b142400000e", response
    r = @c.transaction "5011f33df8182b142400000e"
    r.transaction.id.should == "5011f33df8182b142400000e"
    r.transaction.status.should == "pending"
    r.transaction.amount.should == "-0.01".to_money("BTC")
  end

  it "should not fail if there are no transactions" do
    response = {"current_user"=>{"id"=>"5011f33df8182b142400000e", "email"=>"user2@example.com", "name"=>"user2@example.com"}, "balance"=>{"amount"=>"0.00000000", "currency"=>"BTC"}, "total_count"=>0, "num_pages"=>0, "current_page"=>1}
    fake :get, '/transactions?page=1', response
    r = @c.transactions
    r.transactions.should_not be_nil
  end

  context "send money" do

    it "should allow sending BTC" do
      response = {"success"=>true, "transaction"=>{"id"=>"501a1791f8182b2071000087", "created_at"=>"2012-08-01T23:00:49-07:00", "notes"=>"Sample transaction for you!", "amount"=>{"amount"=>"-1.23400000", "currency"=>"BTC"}, "request"=>false, "status"=>"pending", "sender"=>{"id"=>"5011f33df8182b142400000e", "name"=>"User Two", "email"=>"user2@example.com"}, "recipient"=>{"id"=>"5011f33df8182b142400000a", "name"=>"User One", "email"=>"user1@example.com"}}}
      fake :post, '/transactions/send_money', response
      r = @c.send_money "user1@example.com", 1.2345, "Sample transaction for you"

      # Ensure BTC is assumed to be the default currency
      post_params = JSON.parse(FakeWeb.last_request.body)
      post_params['transaction']['amount_currency_iso'].should == "BTC"
      post_params['transaction']['amount_string'].should == "1.23450000"

      r.success.should == true
      r.transaction.id.should == '501a1791f8182b2071000087'
    end

    it "should allow sending USD" do
      response = {"success"=>true, "transaction"=>{"id"=>"501a1791f8182b2071000087", "created_at"=>"2012-08-01T23:00:49-07:00", "notes"=>"Sample transaction for you!", "amount"=>{"amount"=>"-1.23400000", "currency"=>"BTC"}, "request"=>false, "status"=>"pending", "sender"=>{"id"=>"5011f33df8182b142400000e", "name"=>"User Two", "email"=>"user2@example.com"}, "recipient"=>{"id"=>"5011f33df8182b142400000a", "name"=>"User One", "email"=>"user1@example.com"}}}
      fake :post, '/transactions/send_money', response
      r = @c.send_money "user1@example.com", 500.to_money("USD"), "Sample transaction for you"

      post_params = JSON.parse(FakeWeb.last_request.body)
      post_params['transaction']['amount_currency_iso'].should == "USD"
      post_params['transaction']['amount_string'].should == "500.00"

      r.success.should == true
      r.transaction.id.should == '501a1791f8182b2071000087'
    end

    it "should handle 2FA challenge" do
      response = {success: false, error: "Can i haz 2FA?"}
      fake :post, '/transactions/send_money', response, {status: ["402", "Payment Required"]}
      expect {@c.send_money "user1@example.com", 1.2345, "Sample transaction for you"}.to raise_error(Coinbase::Client::TwoFactorAuthError, "Can i haz 2FA?")
    end

    # FIXME we can't test this using fakeweb: we need to test the header gets set
    it "should allow sending the 2FA code"

  end

  it "should request money" do
    response = {"success"=>true, "transaction"=>{"id"=>"501a3554f8182b2754000003", "created_at"=>"2012-08-02T01:07:48-07:00", "notes"=>"Sample request for you!", "amount"=>{"amount"=>"1.23400000", "currency"=>"BTC"}, "request"=>true, "status"=>"pending", "sender"=>{"id"=>"5011f33df8182b142400000a", "name"=>"User One", "email"=>"user1@example.com"}, "recipient"=>{"id"=>"5011f33df8182b142400000e", "name"=>"User Two", "email"=>"user2@example.com"}}}
    fake :post, '/transactions/request_money', response
    r = @c.request_money "user1@example.com", 1.2345, "Sample transaction for you"

    # Ensure BTC is assumed to be the default currency
    post_params = JSON.parse(FakeWeb.last_request.body)
    post_params['transaction']['amount_currency_iso'].should == "BTC"
    post_params['transaction']['amount_string'].should == "1.23450000"

    r.success.should == true
    r.transaction.id.should == '501a3554f8182b2754000003'
  end

  it "should request money in USD" do
    response = {"success"=>true, "transaction"=>{"id"=>"501a3554f8182b2754000003", "created_at"=>"2012-08-02T01:07:48-07:00", "notes"=>"Sample request for you!", "amount"=>{"amount"=>"1.23400000", "currency"=>"BTC"}, "request"=>true, "status"=>"pending", "sender"=>{"id"=>"5011f33df8182b142400000a", "name"=>"User One", "email"=>"user1@example.com"}, "recipient"=>{"id"=>"5011f33df8182b142400000e", "name"=>"User Two", "email"=>"user2@example.com"}}}
    fake :post, '/transactions/request_money', response
    r = @c.request_money "user1@example.com", 500.to_money("USD"), "Sample transaction for you"

    # Ensure BTC is assumed to be the default currency
    post_params = JSON.parse(FakeWeb.last_request.body)
    post_params['transaction']['amount_currency_iso'].should == "USD"
    post_params['transaction']['amount_string'].should == "500.00"

    r.success.should == true
    r.transaction.id.should == '501a3554f8182b2754000003'
  end

  it "should resend requests" do
    response = {"success"=>true}
    fake :put, "/transactions/501a3554f8182b2754000003/resend_request", response
    r = @c.resend_request '501a3554f8182b2754000003'
    r.success.should == true
  end

  it "should cancel requests" do
    response = {"success"=>true}
    fake :delete, "/transactions/501a3554f8182b2754000003/cancel_request", response
    r = @c.cancel_request '501a3554f8182b2754000003'
    r.success.should == true
  end

  it "should resend requests" do
    response = {"success"=>true}
    fake :put, "/transactions/501a3554f8182b2754000003/complete_request", response
    r = @c.complete_request '501a3554f8182b2754000003'
    r.success.should == true
  end

  # Users

  it "should let you create users" do
    response = {"success"=>true, "user"=>{"id"=>"501a3d22f8182b2754000011", "name"=>"New User", "email"=>"newuser@example.com", "receive_address"=>"mpJKwdmJKYjiyfNo26eRp4j6qGwuUUnw9x"}}
    fake :post, "/users", response
    r = @c.create_user "newuser@example.com"
    r.success.should == true
    r.user.email.should == "newuser@example.com"
    r.user.receive_address.should == "mpJKwdmJKYjiyfNo26eRp4j6qGwuUUnw9x"
  end

  it "should let you create users with OAuth" do
    response = {
      "success"=>true,
      "oauth" => {
        "access_token" => "the_access_token",
        "refresh_token" => "the_refresh_token",
        "scope" => "transactions buy sell",
        "token_type" => "bearer"
      },
      "user" => {
        "id"=>"501a3d22f8182b2754000011",
        "name"=>"New User",
        "email"=>"newuser@example.com",
        "receive_address"=>"mpJKwdmJKYjiyfNo26eRp4j6qGwuUUnw9x"
      }
    }
    fake :post, "/users", response
    r = @c.create_user "newuser@example.com", "newpassword", "the_client_id", ['transactions', 'buy', 'sell']
    r.success.should == true
    r.oauth.access_token.should == "the_access_token"
    r.user.email.should == "newuser@example.com"
    r.user.receive_address.should == "mpJKwdmJKYjiyfNo26eRp4j6qGwuUUnw9x"
  end

  it "should not let you specify client_id without scopes" do
    expect{ @c.create_user "newuser@example.com", "newpassword", "the_client_id" }.to raise_error(Coinbase::Client::Error)
  end

  # Prices

  it "should let you get buy, sell, and spot prices" do
    fake :get, "/prices/buy?qty=1", {"amount"=>"13.85", "currency"=>"USD"}
    r = @c.buy_price 1
    r.to_f.should == 13.85

    fake :get, "/prices/sell?qty=1", {"amount"=>"13.83", "currency"=>"USD"}
    r = @c.sell_price 1
    r.to_f.should == 13.83

    fake :get, "/prices/spot_rate?currency=USD", {"amount"=>"13.84", "currency"=>"USD"}
    r = @c.spot_price
    r.to_f.should == 13.84
  end

  # Buys

  it "should let you buy bitcoin" do
    response = {"success"=>true, "transfer"=>{"_type"=>"AchDebit", "code"=>"6H7GYLXZ", "created_at"=>"2013-01-28T16:08:58-08:00", "fees"=>{"coinbase"=>{"cents"=>14, "currency_iso"=>"USD"}, "bank"=>{"cents"=>15, "currency_iso"=>"USD"}}, "status"=>"created", "payout_date"=>"2013-02-01T18:00:00-08:00", "btc"=>{"amount"=>"1.00000000", "currency"=>"BTC"}, "subtotal"=>{"amount"=>"13.55", "currency"=>"USD"}, "total"=>{"amount"=>"13.84", "currency"=>"USD"}}}
    fake :post, "/buys", response
    r = @c.buy! 1
    r.success?.should == true
    r.transfer.code.should == '6H7GYLXZ'
    r.transfer.status.should == 'created'
    r.transfer.btc.should == 1.to_money("BTC")
  end

  # Sells

  it "should let you sell bitcoin" do
    response = {"success"=>true, "transfer"=>{"_type"=>"AchCredit", "code"=>"RD2OC8AL", "created_at"=>"2013-01-28T16:32:35-08:00", "fees"=>{"coinbase"=>{"cents"=>14, "currency_iso"=>"USD"}, "bank"=>{"cents"=>15, "currency_iso"=>"USD"}}, "status"=>"created", "payout_date"=>"2013-02-01T18:00:00-08:00", "btc"=>{"amount"=>"1.00000000", "currency"=>"BTC"}, "subtotal"=>{"amount"=>"13.50", "currency"=>"USD"}, "total"=>{"amount"=>"13.21", "currency"=>"USD"}}}
    fake :post, "/sells", response
    r = @c.sell! 1
    r.success?.should == true
    r.transfer.code.should == 'RD2OC8AL'
    r.transfer.status.should == 'created'
    r.transfer.btc.should == 1.to_money("BTC")
  end

  # Transfers

  it "should get recent transfers" do
    response = {"transfers" => [{"transfer" => {"type" => "Buy", "code" => "QPCUCZHR", "created_at" => "2013-02-27T23:28:18-08:00", "fees" => {"coinbase" => {"cents" => 14, "currency_iso" => "USD"}, "bank" => {"cents" => 15, "currency_iso" => "USD"} }, "payout_date" => "2013-03-05T18:00:00-08:00", "transaction_id" => "5011f33df8182b142400000e", "status" => "Pending", "btc" => {"amount" => "1.00000000", "currency" => "BTC"}, "subtotal" => {"amount" => "13.55", "currency" => "USD"}, "total" => {"amount" => "13.84", "currency" => "USD"}, "description" => "Paid for with $13.84 from Test xxxxx3111."} } ], "total_count" => 1, "num_pages" => 1, "current_page" => 1 }
    fake :get, "/transfers", response
    r = @c.transfers
    t = r.transfers.first.transfer
    t.type.should == "Buy"
    t.code.should == "QPCUCZHR"
    t.status.should == "Pending"
    t.btc.should == 1.to_money("BTC")
  end

  it "should support pagination" do
    response = {"transfers" => [{"transfer" => {"type" => "Buy", "code" => "QPCUCZHZ", "created_at" => "2013-02-27T23:28:18-08:00", "fees" => {"coinbase" => {"cents" => 14, "currency_iso" => "USD"}, "bank" => {"cents" => 15, "currency_iso" => "USD"} }, "payout_date" => "2013-03-05T18:00:00-08:00", "transaction_id" => "5011f33df8182b142400000e", "status" => "Pending", "btc" => {"amount" => "1.00000000", "currency" => "BTC"}, "subtotal" => {"amount" => "13.55", "currency" => "USD"}, "total" => {"amount" => "13.84", "currency" => "USD"}, "description" => "Paid for with $13.84 from Test xxxxx3111."} } ], "total_count" => 1, "num_pages" => 1, "current_page" => 1 }
    fake :get, "/transfers?page=2", response
    r = @c.transfers :page => 2
    t = r.transfers.first.transfer
    t.type.should == "Buy"
    t.code.should == "QPCUCZHZ"
    t.status.should == "Pending"
    t.btc.should == 1.to_money("BTC")
    FakeWeb.last_request.path.should include("page=2")
  end

  # Addresses

  it 'should read addresses json' do
    raw_addresses = <<-eos
      {
        "addresses": [
          {
            "address": {
              "address": "moLxGrqWNcnGq4A8Caq8EGP4n9GUGWanj4",
              "callback_url": null,
              "label": "My Label",
              "created_at": "2013-05-09T23:07:08-07:00"
            }
          },
          {
            "address": {
              "address": "mwigfecvyG4MZjb6R5jMbmNcs7TkzhUaCj",
              "callback_url": null,
              "label": null,
              "created_at": "2013-05-09T17:50:37-07:00"
            }
          }
        ],
        "total_count": 2,
        "num_pages": 1,
        "current_page": 1
      }
    eos

    fake :get, '/addresses?page=1', JSON.parse(raw_addresses)

    r = @c.addresses
    r.total_count.should == 2
    r.num_pages.should == 1
    r.current_page.should == 1
    r.addresses.size.should == 2
    r.addresses.first.address.address.should == 'moLxGrqWNcnGq4A8Caq8EGP4n9GUGWanj4'
    r.addresses.first.address.callback_url.should == nil
    r.addresses.first.address.label.should == 'My Label'
    r.addresses.first.address.created_at.should == '2013-05-09T23:07:08-07:00'
    r.addresses[1].address.address.should == 'mwigfecvyG4MZjb6R5jMbmNcs7TkzhUaCj'
    r.addresses[1].address.callback_url.should == nil
    r.addresses[1].address.label.should == nil
    r.addresses[1].address.created_at.should == '2013-05-09T17:50:37-07:00'
  end

  it 'should read contacts json' do
    raw_contacts = <<-eos
      {"contacts":
        [
          {"contact":
            {"email": "bit@coin.org"}
          },
          {"contact":
            {"email": "alt@coin.org"}
          }
        ],
        "total_count": 2,
        "num_pages": 1,
        "current_page": 1
      }
    eos

    fake :get, '/contacts?page=1', JSON.parse(raw_contacts)

    r = @c.contacts
    r.total_count.should == 2
    r.num_pages.should == 1
    r.current_page.should == 1
    r.contacts.size.should == 2
    r.contacts.first.contact.email.should == 'bit@coin.org'
    r.contacts[1].contact.email.should == 'alt@coin.org'
  end

  private

  def fake method, path, body, options={}
    FakeWeb.register_uri(method, "#{BASE_URI}#{path}", {body: body.to_json}.merge(options))
  end

end

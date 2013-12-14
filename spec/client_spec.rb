require 'fakeweb'
require 'coinbase'

describe Coinbase::Client do
  BASE_URI = 'http://fake.com/api/v1' # switching to http (instead of https) seems to help FakeWeb

  before :all do
    @c = Coinbase::Client.new 'api key', {base_uri: BASE_URI}
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

  # Buttons

  it "should create a new button" do
    response = {:success=>true, :button=>{:code=>"93865b9cae83706ae59220c013bc0afd", :type=>"buy_now", :style=>"custom_large", :text=>"Pay With Bitcoin", :name=>"Order 123", :description=>"Sample description", :custom=>"Order123", :price=>{:cents=>123, :currency_iso=>"BTC"}}}
    fake :post, '/buttons', response
    r = @c.create_button "Order 123", 1.23, "Sample description"
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
    fake :get, '/transactions', response
    r = @c.transactions
    r.transactions.first.transaction.id.should == '5018f833f8182b129c00002f'
    r.transactions.last.transaction.hsh.should == '9d6a7d1112c3db9de5315b421a5153d71413f5f752aff75bf504b77df4e646a3'
  end

  it "should not fail if there are no transactions" do
    response = {"current_user"=>{"id"=>"5011f33df8182b142400000e", "email"=>"user2@example.com", "name"=>"user2@example.com"}, "balance"=>{"amount"=>"0.00000000", "currency"=>"BTC"}, "total_count"=>0, "num_pages"=>0, "current_page"=>1}
    fake :get, '/transactions', response
    r = @c.transactions
    r.transactions.should_not be_nil
  end

  it "should send money" do
    response = {"success"=>true, "transaction"=>{"id"=>"501a1791f8182b2071000087", "created_at"=>"2012-08-01T23:00:49-07:00", "notes"=>"Sample transaction for you!", "amount"=>{"amount"=>"-1.23400000", "currency"=>"BTC"}, "request"=>false, "status"=>"pending", "sender"=>{"id"=>"5011f33df8182b142400000e", "name"=>"User Two", "email"=>"user2@example.com"}, "recipient"=>{"id"=>"5011f33df8182b142400000a", "name"=>"User One", "email"=>"user1@example.com"}}}
    fake :post, '/transactions/send_money', response
    r = @c.send_money "user1@example.com", 1.2345, "Sample transaction for you"
    r.success.should == true
    r.transaction.id.should == '501a1791f8182b2071000087'
  end

  it "should request money" do
    response = {"success"=>true, "transaction"=>{"id"=>"501a3554f8182b2754000003", "created_at"=>"2012-08-02T01:07:48-07:00", "notes"=>"Sample request for you!", "amount"=>{"amount"=>"1.23400000", "currency"=>"BTC"}, "request"=>true, "status"=>"pending", "sender"=>{"id"=>"5011f33df8182b142400000a", "name"=>"User One", "email"=>"user1@example.com"}, "recipient"=>{"id"=>"5011f33df8182b142400000e", "name"=>"User Two", "email"=>"user2@example.com"}}}
    fake :post, '/transactions/request_money', response
    r = @c.request_money "user1@example.com", 1.2345, "Sample transaction for you"
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

  # Prices

  it "should let you get buy and sell prices" do
    response = {"amount"=>"13.84", "currency"=>"USD"}
    fake :get, "/prices/buy", response
    r = @c.buy_price 1
    r.to_f.should == 13.84

    fake :get, "/prices/sell", response
    r = @c.sell_price 1
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
    r.transfer.btc.should == 1.to_money
  end

  # Sells

  it "should let you sell bitcoin" do
    response = {"success"=>true, "transfer"=>{"_type"=>"AchCredit", "code"=>"RD2OC8AL", "created_at"=>"2013-01-28T16:32:35-08:00", "fees"=>{"coinbase"=>{"cents"=>14, "currency_iso"=>"USD"}, "bank"=>{"cents"=>15, "currency_iso"=>"USD"}}, "status"=>"created", "payout_date"=>"2013-02-01T18:00:00-08:00", "btc"=>{"amount"=>"1.00000000", "currency"=>"BTC"}, "subtotal"=>{"amount"=>"13.50", "currency"=>"USD"}, "total"=>{"amount"=>"13.21", "currency"=>"USD"}}}
    fake :post, "/sells", response
    r = @c.sell! 1
    r.success?.should == true
    r.transfer.code.should == 'RD2OC8AL'
    r.transfer.status.should == 'created'
    r.transfer.btc.should == 1.to_money
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
    t.btc.should == 1.to_money
  end


  private

  def fake method, path, body
    FakeWeb.register_uri(method, "#{BASE_URI}#{path}", body: body.to_json)
  end
end

require 'fakeweb'
require 'coinbase'

describe Coinbase::Client do
  BASE_URI = 'http://fake.com/api/v1' # switching to http (instead of https) seems to help FakeWeb

  before :all do
    @c = Coinbase::Client.new 'api key', 'api secret', {base_uri: BASE_URI}
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
    fake :get, '/transactions', response
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
    fake :get, '/transactions', response
    r = @c.transactions
    r.transactions.should_not be_nil
  end

  it "should send money in BTC" do
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

  it "should send money in USD" do
    response = {"success"=>true, "transaction"=>{"id"=>"501a1791f8182b2071000087", "created_at"=>"2012-08-01T23:00:49-07:00", "notes"=>"Sample transaction for you!", "amount"=>{"amount"=>"-1.23400000", "currency"=>"BTC"}, "request"=>false, "status"=>"pending", "sender"=>{"id"=>"5011f33df8182b142400000e", "name"=>"User Two", "email"=>"user2@example.com"}, "recipient"=>{"id"=>"5011f33df8182b142400000a", "name"=>"User One", "email"=>"user1@example.com"}}}
    fake :post, '/transactions/send_money', response
    r = @c.send_money "user1@example.com", 500.to_money("USD"), "Sample transaction for you"

    post_params = JSON.parse(FakeWeb.last_request.body)
    post_params['transaction']['amount_currency_iso'].should == "USD"
    post_params['transaction']['amount_string'].should == "500.00"

    r.success.should == true
    r.transaction.id.should == '501a1791f8182b2071000087'
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
    fake :get, "/prices/buy", {"amount"=>"13.85", "currency"=>"USD"}
    r = @c.buy_price 1
    r.to_f.should == 13.85

    fake :get, "/prices/sell", {"amount"=>"13.83", "currency"=>"USD"}
    r = @c.sell_price 1
    r.to_f.should == 13.83

    fake :get, "/prices/spot_rate", {"amount"=>"13.84", "currency"=>"USD"}
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

  # Currencies

  it "should get a list of currency exchanges" do
    response = {"gbp_to_usd"=>"1.633667", "usd_to_bwp"=>"8.62852", "usd_to_azn"=>"0.784167", "eur_to_usd"=>"1.35924", "usd_to_czk"=>"20.11621", "czk_to_btc"=>"5.6e-05", "btc_to_mga"=>"1999686.885067", "btc_to_djf"=>"158147.411834", "idr_to_btc"=>"0.0", "mnt_to_usd"=>"0.00058", "usd_to_ngn"=>"158.682199", "usd_to_gbp"=>"0.61212", "irr_to_btc"=>"0.0", "ils_to_usd"=>"0.282751", "ars_to_usd"=>"0.163763", "usd_to_uyu"=>"21.16168", "uyu_to_btc"=>"5.3e-05", "pyg_to_btc"=>"0.0", "usd_to_yer"=>"215.006099", "pgk_to_usd"=>"0.387254", "xcd_to_btc"=>"0.000416", "usd_to_fjd"=>"1.870015", "dop_to_btc"=>"2.7e-05", "mvr_to_usd"=>"0.06503", "eek_to_usd"=>"0.085636", "nzd_to_btc"=>"0.000918", "gnf_to_btc"=>"0.0", "usd_to_gtq"=>"7.88508", "bmd_to_usd"=>"1.0", "btc_to_lbp"=>"1338220.674541", "usd_to_omr"=>"0.385012", "usd_to_sos"=>"1207.4067", "usd_to_thb"=>"32.11708", "srd_to_btc"=>"0.000343", "btc_to_all"=>"91888.63729", "usd_to_vnd"=>"21106.95", "htg_to_usd"=>"0.025083", "btc_to_bmd"=>"888.93805", "kpw_to_usd"=>"0.0", "lyd_to_usd"=>"0.804161", "tzs_to_btc"=>"1.0e-06", "lak_to_usd"=>"0.000125", "usd_to_idr"=>"11907.583333", "btc_to_bzd"=>"1770.195675", "usd_to_gel"=>"1.6904", "usd_to_kzt"=>"153.658001", "uah_to_usd"=>"0.121707", "usd_to_lkr"=>"131.201499", "btc_to_zwl"=>"286553.630441", "php_to_btc"=>"2.6e-05", "ron_to_usd"=>"0.306263", "btc_to_kyd"=>"734.803304", "btc_to_cad"=>"940.246665", "hkd_to_btc"=>"0.000145", "usd_to_btc"=>"0.001125", "nok_to_btc"=>"0.000185", "top_to_usd"=>"0.548145", "btc_to_xpf"=>"78126.987338", "usd_to_kgs"=>"48.862875", "usd_to_bnd"=>"1.25468", "dzd_to_usd"=>"0.012516", "vef_to_btc"=>"0.000179", "usd_to_ars"=>"6.106376", "syp_to_btc"=>"8.0e-06", "ngn_to_btc"=>"7.0e-06", "bgn_to_btc"=>"0.000782", "lak_to_btc"=>"0.0", "btc_to_cve"=>"71977.305019", "mga_to_btc"=>"1.0e-06", "idr_to_usd"=>"8.4e-05", "btc_to_htg"=>"35439.725263", "btc_to_ils"=>"3143.884978", "mad_to_btc"=>"0.000136", "usd_to_hnl"=>"20.52386", "svc_to_btc"=>"0.000129", "btc_to_ang"=>"1590.274614", "hkd_to_usd"=>"0.12899", "usd_to_nad"=>"10.20123", "szl_to_btc"=>"0.00011", "etb_to_usd"=>"0.052406", "pkr_to_btc"=>"1.0e-05", "usd_to_khr"=>"4003.966833", "gnf_to_usd"=>"0.000144", "btc_to_myr"=>"2870.615643", "btc_to_top"=>"1621.720797", "nad_to_btc"=>"0.00011", "huf_to_usd"=>"0.004546", "mkd_to_btc"=>"2.5e-05", "lkr_to_btc"=>"9.0e-06", "svc_to_usd"=>"0.114311", "btc_to_lyd"=>"1105.422911", "usd_to_bam"=>"1.440026", "usd_to_svc"=>"8.74805", "usd_to_tzs"=>"1609.666667", "gbp_to_btc"=>"0.001838", "btc_to_mop"=>"7097.761418", "btc_to_jod"=>"629.416142", "clp_to_usd"=>"0.001896", "cad_to_usd"=>"0.945431", "cny_to_btc"=>"0.000184", "jod_to_btc"=>"0.001589", "syp_to_usd"=>"0.007141", "lvl_to_btc"=>"0.002175", "btc_to_cny"=>"5422.419877", "shp_to_btc"=>"0.001838", "vef_to_usd"=>"0.158944", "php_to_usd"=>"0.022869", "mro_to_usd"=>"0.003427", "tjs_to_btc"=>"0.000236", "fkp_to_btc"=>"0.001838", "bdt_to_usd"=>"0.012869", "mkd_to_usd"=>"0.021979", "lrd_to_usd"=>"0.012418", "usd_to_kes"=>"87.034389", "btc_to_ars"=>"5428.189974", "usd_to_chf"=>"0.906341", "usd_to_lak"=>"7987.781667", "usd_to_bzd"=>"1.99136", "usd_to_nzd"=>"1.225977", "mvr_to_btc"=>"7.3e-05", "usd_to_wst"=>"2.344837", "nok_to_usd"=>"0.164135", "tjs_to_usd"=>"0.209516", "bob_to_usd"=>"0.144729", "btc_to_cup"=>"20163.676005", "afn_to_btc"=>"2.0e-05", "vnd_to_btc"=>"0.0", "bnd_to_usd"=>"0.797016", "byr_to_btc"=>"0.0", "aed_to_btc"=>"0.000306", "hnl_to_btc"=>"5.5e-05", "mmk_to_usd"=>"0.001018", "zmk_to_btc"=>"0.0", "usd_to_myr"=>"3.229264", "usd_to_ils"=>"3.536675", "usd_to_mdl"=>"13.1323", "djf_to_usd"=>"0.005621", "mnt_to_btc"=>"1.0e-06", "usd_to_sbd"=>"7.143096", "lbp_to_usd"=>"0.000664", "aoa_to_btc"=>"1.2e-05", "btc_to_vnd"=>"18762770.974447", "btc_to_lak"=>"7100643.058889", "dkk_to_usd"=>"0.182213", "inr_to_btc"=>"1.8e-05", "lrd_to_btc"=>"1.4e-05", "pab_to_btc"=>"0.001125", "usd_to_mga"=>"2249.523333", "btc_to_awg"=>"1591.065769", "usd_to_try"=>"2.015658", "usd_to_qar"=>"3.641038", "usd_to_lvl"=>"0.517161", "bmd_to_btc"=>"0.001125", "vuv_to_btc"=>"1.2e-05", "usd_to_pen"=>"2.80238", "usd_to_zmk"=>"5253.075255", "usd_to_ttd"=>"6.41373", "mwk_to_btc"=>"3.0e-06", "btc_to_scr"=>"10736.55821", "egp_to_btc"=>"0.000163", "bam_to_btc"=>"0.000781", "usd_to_kmf"=>"362.286958", "btc_to_aed"=>"3264.928117", "usd_to_shp"=>"0.61212", "bbd_to_btc"=>"0.0", "kes_to_usd"=>"0.01149", "jpy_to_btc"=>"1.1e-05", "wst_to_usd"=>"0.426469", "gyd_to_usd"=>"0.004843", "kgs_to_btc"=>"2.3e-05", "btc_to_eek"=>"10380.418515", "usd_to_php"=>"43.72676", "sdg_to_usd"=>"0.225802", "usd_to_isk"=>"120.165", "scr_to_btc"=>"9.3e-05", "cup_to_usd"=>"0.044086", "std_to_btc"=>"0.0", "usd_to_gip"=>"0.61212", "usd_to_aud"=>"1.0963", "usd_to_dzd"=>"79.89655", "usd_to_xaf"=>"483.051199", "usd_to_mro"=>"291.7967", "clp_to_btc"=>"2.0e-06", "bbd_to_usd"=>"0.0", "mdl_to_btc"=>"8.6e-05", "btc_to_pyg"=>"3929049.928111", "xof_to_btc"=>"2.0e-06", "kzt_to_btc"=>"7.0e-06", "usd_to_irr"=>"24785.667967", "usd_to_vuv"=>"96.5375", "bif_to_btc"=>"1.0e-06", "btc_to_gtq"=>"7009.347639", "usd_to_bif"=>"1551.3184", "btc_to_xof"=>"429968.666639", "btc_to_ghs"=>"2020.911763", "btc_to_kes"=>"77368.180041", "usd_to_bbd"=>"2", "usd_to_afn"=>"57.430025", "usd_to_sdg"=>"4.428657", "uzs_to_usd"=>"0.00046", "btc_to_dzd"=>"71023.083359", "btc_to_uyu"=>"18811.422554", "usd_to_mnt"=>"1725.083333", "egp_to_usd"=>"0.145211", "btc_to_nio"=>"22379.602108", "usd_to_mur"=>"30.35621", "usd_to_fkp"=>"0.61212", "twd_to_usd"=>"0.033739", "btc_to_bif"=>"1379025.953425", "nio_to_btc"=>"4.5e-05", "bhd_to_usd"=>"2.652604", "aoa_to_usd"=>"0.010273", "tmm_to_usd"=>"0.350652", "btc_to_bhd"=>"335.118978", "kyd_to_btc"=>"0.001361", "usd_to_mzn"=>"29.89945", "jmd_to_btc"=>"1.1e-05", "lbp_to_btc"=>"1.0e-06", "btc_to_ngn"=>"141058.644549", "sek_to_btc"=>"0.000171", "try_to_usd"=>"0.496116", "btc_to_mkd"=>"40444.556713", "btc_to_gbp"=>"544.136759", "aud_to_btc"=>"0.001026", "xpf_to_usd"=>"0.011378", "bzd_to_btc"=>"0.000565", "usd_to_cdf"=>"921.303003", "btc_to_bdt"=>"69075.748998", "cup_to_btc"=>"5.0e-05", "usd_to_lsl"=>"10.19269", "btc_to_tnd"=>"1481.973513", "btc_to_pln"=>"2744.550005", "usd_to_btn"=>"62.405663", "zar_to_btc"=>"0.00011", "bob_to_btc"=>"0.000163", "usd_to_top"=>"1.824335", "amd_to_btc"=>"3.0e-06", "btc_to_syp"=>"124475.771907", "szl_to_usd"=>"0.098101", "gip_to_usd"=>"1.633667", "usd_to_mvr"=>"15.37749", "thb_to_usd"=>"0.031136", "bgn_to_usd"=>"0.694751", "btc_to_gnf"=>"6165712.835153", "rwf_to_btc"=>"2.0e-06", "cny_to_usd"=>"0.163938", "btc_to_mzn"=>"26578.758779", "btc_to_bob"=>"6142.090788", "btc_to_etb"=>"16962.395852", "ern_to_usd"=>"0.066235", "mmk_to_btc"=>"1.0e-06", "btc_to_uzs"=>"1931941.125176", "usd_to_kwd"=>"0.282781", "btc_to_twd"=>"26347.794895", "usd_to_clp"=>"527.4221", "ghs_to_usd"=>"0.43987", "brl_to_btc"=>"0.000485", "btc_to_try"=>"1791.795092", "usd_to_dkk"=>"5.488097", "myr_to_btc"=>"0.000348", "btc_to_svc"=>"7776.474508", "kmf_to_btc"=>"3.0e-06", "mxn_to_btc"=>"8.6e-05", "nio_to_usd"=>"0.039721", "uah_to_btc"=>"0.000137", "ttd_to_btc"=>"0.000175", "usd_to_sgd"=>"1.254902", "usd_to_hrk"=>"5.615268", "btc_to_thb"=>"28550.094467", "mwk_to_usd"=>"0.002446", "btc_to_aud"=>"974.542784", "btc_to_vuv"=>"85815.857002", "btc_to_php"=>"38870.380767", "pyg_to_usd"=>"0.000226", "scr_to_usd"=>"0.082795", "btc_to_kwd"=>"251.374791", "ugx_to_usd"=>"0.000396", "btc_to_gmd"=>"33591.155476", "zwl_to_btc"=>"3.0e-06", "btc_to_zar"=>"9069.212668", "btc_to_hkd"=>"6891.55268", "btc_to_afn"=>"51051.734435", "btc_to_fkp"=>"544.136759", "xaf_to_btc"=>"2.0e-06", "usd_to_nok"=>"6.092554", "btc_to_kzt"=>"136592.443776", "btc_to_btn"=>"55474.768376", "amd_to_usd"=>"0.002449", "usd_to_syp"=>"140.027499", "usd_to_jpy"=>"102.181201", "usd_to_sek"=>"6.570703", "btc_to_clp"=>"468845.573101", "sgd_to_usd"=>"0.796875", "btc_to_qar"=>"3236.65722", "czk_to_usd"=>"0.049711", "usd_to_aoa"=>"97.343626", "krw_to_usd"=>"0.000942", "sar_to_usd"=>"0.266627", "hnl_to_usd"=>"0.048724", "bwp_to_usd"=>"0.115895", "usd_to_brl"=>"2.319796", "btc_to_bbd"=>"1777.8761", "ngn_to_usd"=>"0.006302", "azn_to_usd"=>"1.275239", "btc_to_mnt"=>"1533492.214125", "usd_to_rub"=>"33.12431", "btc_to_lvl"=>"459.724091", "usd_to_ron"=>"3.265171", "btc_to_azn"=>"697.075884", "sll_to_usd"=>"0.000232", "usd_to_dop"=>"42.3681", "pab_to_usd"=>"1.0", "pkr_to_usd"=>"0.009223", "usd_to_scr"=>"12.07796", "usd_to_huf"=>"219.952799", "bdt_to_btc"=>"1.4e-05", "btc_to_crc"=>"439769.207752", "std_to_usd"=>"5.5e-05", "mzn_to_usd"=>"0.033445", "mzn_to_btc"=>"3.8e-05", "nzd_to_usd"=>"0.815676", "btc_to_npr"=>"88656.014961", "btc_to_bwp"=>"7670.219743", "kwd_to_usd"=>"3.536305", "omr_to_usd"=>"2.597322", "btc_to_rwf"=>"600360.508519", "kgs_to_usd"=>"0.020465", "afn_to_usd"=>"0.017412", "btc_to_egp"=>"6121.693216", "aud_to_usd"=>"0.912159", "usd_to_mwk"=>"408.8331", "usd_to_cny"=>"6.099885", "rwf_to_usd"=>"0.001481", "usd_to_zwl"=>"322.355006", "btc_to_cdf"=>"818981.294946", "usd_to_tjs"=>"4.7729", "usd_to_all"=>"103.369", "bhd_to_btc"=>"0.002984", "kpw_to_btc"=>"0.0", "bam_to_usd"=>"0.694432", "btc_to_szl"=>"9061.452238", "usd_to_pyg"=>"4419.936719", "gel_to_btc"=>"0.000666", "xcd_to_usd"=>"0.370165", "usd_to_lrd"=>"80.528251", "sos_to_usd"=>"0.000828", "usd_to_uzs"=>"2173.313568", "btc_to_fjd"=>"1662.327488", "btc_to_iqd"=>"1034670.598364", "usd_to_bsd"=>"1", "cve_to_btc"=>"1.4e-05", "rub_to_btc"=>"3.4e-05", "usd_to_rsd"=>"83.906211", "sar_to_btc"=>"0.0003", "eek_to_btc"=>"9.6e-05", "btc_to_ugx"=>"2244746.378083", "awg_to_btc"=>"0.000629", "btc_to_mwk"=>"363427.298689", "huf_to_btc"=>"5.0e-06", "ang_to_usd"=>"0.558984", "usd_to_djf"=>"177.905999", "usd_to_cad"=>"1.057719", "btc_to_brl"=>"2062.154933", "usd_to_ern"=>"15.097825", "iqd_to_btc"=>"1.0e-06", "btc_to_pgk"=>"2295.489615", "usd_to_xcd"=>"2.7015", "btn_to_btc"=>"1.8e-05", "myr_to_usd"=>"0.309668", "lsl_to_usd"=>"0.09811", "crc_to_usd"=>"0.002021", "usd_to_egp"=>"6.886524", "btc_to_rsd"=>"74587.423589", "gel_to_usd"=>"0.591576", "jmd_to_usd"=>"0.009719", "btc_to_ltl"=>"2258.393341", "lyd_to_btc"=>"0.000905", "nad_to_usd"=>"0.098027", "usd_to_kyd"=>"0.826608", "btc_to_bsd"=>"888.93805", "ltl_to_btc"=>"0.000443", "usd_to_srd"=>"3.283333", "usd_to_awg"=>"1.78985", "usd_to_szl"=>"10.19357", "chf_to_btc"=>"0.001241", "zwl_to_usd"=>"0.003102", "sll_to_btc"=>"0.0", "usd_to_cop"=>"1927.433333", "usd_to_tmm"=>"2.851833", "btc_to_tjs"=>"4242.812419", "sbd_to_btc"=>"0.000157", "ern_to_btc"=>"7.5e-05", "btc_to_bam"=>"1280.093904", "btc_to_gip"=>"544.136759", "sbd_to_usd"=>"0.139995", "mad_to_usd"=>"0.121088", "btc_to_ern"=>"13421.031115", "usd_to_ltl"=>"2.540552", "qar_to_usd"=>"0.274647", "usd_to_kpw"=>"900", "usd_to_crc"=>"494.712998", "usd_to_xpf"=>"87.888", "yer_to_btc"=>"5.0e-06", "chf_to_usd"=>"1.103337", "jpy_to_usd"=>"0.009787", "ars_to_btc"=>"0.000184", "usd_to_pgk"=>"2.582283", "gyd_to_btc"=>"5.0e-06", "aed_to_usd"=>"0.272269", "usd_to_mop"=>"7.98454", "usd_to_aed"=>"3.672841", "qar_to_btc"=>"0.000309", "btc_to_sll"=>"3837842.02269", "btc_to_dkk"=>"4878.578245", "gtq_to_usd"=>"0.126822", "sos_to_btc"=>"1.0e-06", "dop_to_usd"=>"0.023603", "awg_to_usd"=>"0.558706", "btc_to_gel"=>"1502.66088", "btc_to_lkr"=>"116630.004678", "btc_to_lrd"=>"71584.626414", "khr_to_usd"=>"0.00025", "btc_to_hrk"=>"4991.625386", "usd_to_etb"=>"19.08164", "btc_to_sos"=>"1073309.757455", "btc_to_eur"=>"653.996168", "usd_to_krw"=>"1061.26498", "btc_to_dop"=>"37662.616196", "usd_to_bob"=>"6.90947", "btc_to_kgs"=>"43436.06882", "cve_to_usd"=>"0.01235", "fjd_to_usd"=>"0.534755", "btc_to_jpy"=>"90832.757564", "btc_to_omr"=>"342.251817", "usd_to_gyd"=>"206.501249", "pen_to_btc"=>"0.000401", "btc_to_jmd"=>"91465.502779", "npr_to_usd"=>"0.010027", "usd_to_tnd"=>"1.667128", "usd_to_twd"=>"29.63963", "btc_to_nad"=>"9068.261504", "azn_to_btc"=>"0.001435", "btc_to_sgd"=>"1115.530137", "twd_to_btc"=>"3.8e-05", "btc_to_sek"=>"5840.947912", "inr_to_usd"=>"0.016031", "crc_to_btc"=>"2.0e-06", "usd_to_mxn"=>"13.10359", "xaf_to_usd"=>"0.00207", "btc_to_idr"=>"10585103.90825", "btc_to_hnl"=>"18244.440087", "eur_to_btc"=>"0.001529", "btc_to_sbd"=>"6349.769829", "hrk_to_usd"=>"0.178086", "pln_to_btc"=>"0.000364", "gtq_to_btc"=>"0.000143", "zmk_to_usd"=>"0.00019", "thb_to_btc"=>"3.5e-05", "btc_to_mvr"=>"13669.635974", "ghs_to_btc"=>"0.000495", "usd_to_gmd"=>"37.78796", "usd_to_mkd"=>"45.49761", "usd_to_eur"=>"0.735705", "cop_to_btc"=>"1.0e-06", "btc_to_xcd"=>"2401.466142", "sdg_to_btc"=>"0.000254", "btc_to_nzd"=>"1089.817604", "usd_to_uah"=>"8.21647", "rsd_to_btc"=>"1.3e-05", "cdf_to_btc"=>"1.0e-06", "btn_to_usd"=>"0.016024", "krw_to_btc"=>"1.0e-06", "tzs_to_usd"=>"0.000621", "pgk_to_btc"=>"0.000436", "btc_to_byr"=>"8303422.168412", "bsd_to_usd"=>"1.0", "irr_to_usd"=>"4.0e-05", "uyu_to_usd"=>"0.047255", "mop_to_btc"=>"0.000141", "usd_to_ghs"=>"2.2734", "btc_to_khr"=>"3559278.468792", "kyd_to_usd"=>"1.209763", "btc_to_zmk"=>"4669658.473683", "cop_to_usd"=>"0.000519", "btc_to_mad"=>"7341.276218", "try_to_btc"=>"0.000558", "xpf_to_btc"=>"1.3e-05", "kzt_to_usd"=>"0.006508", "usd_to_bhd"=>"0.376988", "top_to_btc"=>"0.000617", "ugx_to_btc"=>"0.0", "usd_to_mmk"=>"982.69002", "usd_to_jod"=>"0.708054", "btc_to_vef"=>"5592.762631", "gip_to_btc"=>"0.001838", "btc_to_mmk"=>"873550.550133", "usd_to_xof"=>"483.687999", "wst_to_btc"=>"0.00048", "mdl_to_usd"=>"0.076148", "ltl_to_usd"=>"0.393615", "bnd_to_btc"=>"0.000897", "usd_to_sll"=>"4317.3335", "usd_to_nio"=>"25.17566", "btc_to_mro"=>"259389.189494", "srd_to_usd"=>"0.304569", "usd_to_lbp"=>"1505.415", "btc_to_pkr"=>"96380.691049", "rsd_to_usd"=>"0.011918", "sgd_to_btc"=>"0.000896", "yer_to_usd"=>"0.004651", "lvl_to_usd"=>"1.933634", "usd_to_ang"=>"1.78896", "usd_to_sar"=>"3.750561", "usd_to_iqd"=>"1163.94005", "btc_to_kmf"=>"322050.661985", "usd_to_bmd"=>"1", "kes_to_btc"=>"1.3e-05", "btc_to_irr"=>"22032923.350532", "btc_to_aoa"=>"86532.453076", "btc_to_shp"=>"544.136759", "btc_to_sdg"=>"3936.801718", "kmf_to_usd"=>"0.00276", "btc_to_krw"=>"943398.821854", "btc_to_srd"=>"2918.679635", "usd_to_bdt"=>"77.70592", "usd_to_zar"=>"10.2023", "bwp_to_btc"=>"0.00013", "byr_to_usd"=>"0.000107", "vnd_to_usd"=>"4.7e-05", "usd_to_cve"=>"80.96999", "btc_to_btc"=>"1.000055", "btc_to_pen"=>"2491.142213", "usd_to_hkd"=>"7.752568", "isk_to_btc"=>"9.0e-06", "pen_to_usd"=>"0.35684", "btc_to_kpw"=>"800044.245", "btc_to_tmm"=>"0.0", "bzd_to_usd"=>"0.502169", "npr_to_btc"=>"1.1e-05", "btc_to_chf"=>"805.681001", "btc_to_bgn"=>"1279.506316", "btc_to_uah"=>"7303.93282", "pln_to_usd"=>"0.323892", "btc_to_inr"=>"55450.142125", "htg_to_btc"=>"2.8e-05", "btc_to_wst"=>"2084.41483", "btc_to_ron"=>"2902.534742", "xof_to_usd"=>"0.002067", "btc_to_mur"=>"26984.790123", "usd_to_rwf"=>"675.36822", "usd_to_pab"=>"1", "btc_to_mxn"=>"11648.279743", "all_to_btc"=>"1.1e-05", "dkk_to_btc"=>"0.000205", "usd_to_ugx"=>"2525.200016", "tnd_to_usd"=>"0.599834", "usd_to_lyd"=>"1.243532", "usd_to_pkr"=>"108.422281", "omr_to_btc"=>"0.002922", "mga_to_usd"=>"0.000445", "mur_to_btc"=>"3.7e-05", "usd_to_amd"=>"408.364003", "jod_to_usd"=>"1.412322", "tnd_to_btc"=>"0.000675", "shp_to_usd"=>"1.633667", "vuv_to_usd"=>"0.010359", "khr_to_btc"=>"0.0", "usd_to_htg"=>"39.867486", "iqd_to_usd"=>"0.000859", "btc_to_sar"=>"3334.016382", "mur_to_usd"=>"0.032942", "lsl_to_btc"=>"0.00011", "usd_to_jmd"=>"102.893", "ils_to_btc"=>"0.000318", "zar_to_usd"=>"0.098017", "usd_to_pln"=>"3.087448", "bsd_to_btc"=>"0.001125", "btc_to_rub"=>"29445.459539", "usd_to_mad"=>"8.258479", "usd_to_inr"=>"62.37796", "btc_to_czk"=>"17882.064491", "isk_to_usd"=>"0.008322", "rub_to_usd"=>"0.030189", "usd_to_usd"=>"1.0", "fkp_to_usd"=>"1.633667", "all_to_usd"=>"0.009674", "mop_to_usd"=>"0.125242", "usd_to_cup"=>"22.682881", "mro_to_btc"=>"4.0e-06", "tmm_to_btc"=>"0.0", "fjd_to_btc"=>"0.000602", "usd_to_gnf"=>"6936.043333", "btc_to_huf"=>"195524.412235", "usd_to_byr"=>"9340.833333", "usd_to_bgn"=>"1.439365", "ang_to_btc"=>"0.000629", "gmd_to_usd"=>"0.026463", "bif_to_usd"=>"0.000645", "etb_to_btc"=>"5.9e-05", "usd_to_std"=>"18145.400667", "btc_to_std"=>"16130137.085392", "btc_to_ttd"=>"5701.408639", "ron_to_btc"=>"0.000345", "gmd_to_btc"=>"3.0e-05", "kwd_to_btc"=>"0.003978", "btc_to_amd"=>"363010.300517", "btc_to_gyd"=>"183566.817609", "btc_to_nok"=>"5415.903072", "btc_to_yer"=>"191127.102383", "cdf_to_usd"=>"0.001085", "btc_to_usd"=>"888.9380499999999", "hrk_to_btc"=>"0.0002", "btc_to_xaf"=>"429402.590889", "btc_to_bnd"=>"1115.332793", "btc_to_lsl"=>"9060.669973", "usd_to_eek"=>"11.677325", "brl_to_usd"=>"0.431072", "lkr_to_usd"=>"0.007622", "btc_to_pab"=>"888.93805", "ttd_to_usd"=>"0.155916", "btc_to_cop"=>"1713368.828542", "btc_to_isk"=>"106819.240778", "uzs_to_btc"=>"1.0e-06", "mxn_to_usd"=>"0.076315", "btc_to_mdl"=>"11673.801154", "djf_to_btc"=>"6.0e-06", "usd_to_npr"=>"99.732501", "btc_to_tzs"=>"1430893.948113", "usd_to_vef"=>"6.29151", "cad_to_btc"=>"0.001064", "dzd_to_btc"=>"1.4e-05", "sek_to_usd"=>"0.152191"}
    fake :get, "/currencies/exchange_rates", response
    r = @c.exchange_rates
    r[:usd_to_btc].should == "0.001125"
    r[:btc_to_usd].should == "888.9380499999999"
  end


  private

  def fake method, path, body
    FakeWeb.register_uri(method, "#{BASE_URI}#{path}", body: body.to_json)
  end

end

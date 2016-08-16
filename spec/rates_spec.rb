require 'spec_helper'
require 'fakeweb'
require 'coinbase'

describe Money::Bank::Coinbase do
  BASE_URI = 'http://fake.com/api/v1' # switching to http (instead of https) seems to help FakeWeb

  before :all do
    @coinbase = Coinbase::Client.new '', '', {base_uri: BASE_URI}
    FakeWeb.allow_net_connect = false
    @rates_response = JSON.parse(File.read(File.dirname(__FILE__) + '/fixtures/rate_response.json'))
    fake :get, '/currencies/exchange_rates', @rates_response
    @bank = Money::Bank::Coinbase.new @coinbase
    @bank.fetch_rates!
    Money.default_bank = @bank
  end

  # Auth and Errors

  it "exposes rates directly" do
    @bank.get_rate(:usd, :btc).should == '0.001532'
  end

  it "lets you convert currencies" do
    Money.us_dollar(100).exchange_to(:BTC).should == '0.001532'.to_money(:BTC)
  end

  it "lets you convert currencies with tiny rates" do
    '1000000'.to_money(:MRO).exchange_to(:BTC).should == '5'.to_money(:BTC)
  end

  it "lets you compare currencies" do
    '1'.to_money(:BTC).should > '1'.to_money(:USD)
  end

  it "throws an exception for unknown currencies" do
    expect{'1'.to_money(:BTC).exchange_to(:WTF)}.to raise_error(Money::Currency::UnknownCurrency)
  end

  it "throws an exception for missing rates" do
    expect{'1'.to_money(:EUR).exchange_to(:RON)}.to raise_error(Money::Bank::UnknownRate)
  end

  it "automatically refreshes expired rates" do
    '1'.to_money(:BTC).exchange_to(:RON).should == '2111.23'.to_money(:RON)
    @rates_response['btc_to_ron'] = '2000'
    fake :get, '/currencies/exchange_rates', @rates_response
    @bank.ttl_in_seconds = 0.2
    sleep 0.3
    '1'.to_money(:BTC).exchange_to(:RON).should == '2000'.to_money(:RON)
  end

  def fake method, path, body
    FakeWeb.register_uri(method, "#{BASE_URI}#{path}", body: body.to_json)
  end

end

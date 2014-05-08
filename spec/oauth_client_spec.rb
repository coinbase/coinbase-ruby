require 'fakeweb'
require 'coinbase'

describe Coinbase::Client do
  BASE_URI = 'http://fake.com/api/v1' # switching to http (instead of https) seems to help FakeWeb

  before :all do
    @credentials = {
      :token => 'access_token',
      :refresh_token => 'refresh_token',
      :expires_at => Time.now.to_i + 100
    }
    @client_options = {
      base_uri: BASE_URI,
      authorize_url: "http://fake.com/oauth/authorize",
      token_url: "http://fake.com/oauth/token"
    }
    @c = Coinbase::OAuthClient.new 'api key', 'api secret', @credentials, @client_options
  end

  # Auth and Errors

  it "raise errors" do
    fake :get, '/account/balance', {error: "some error"}
    expect{ @c.balance }.to raise_error(Coinbase::Client::Error, 'some error')
    fake :get, '/account/balance', {errors: ["some", "error"]}
    expect{ @c.balance }.to raise_error(Coinbase::Client::Error, 'some, error')
  end

  it "should get balance" do
    fake :get, '/account/balance', {amount: "50.00000000", currency: 'BTC'}
    @c.balance.should == 50.to_money('BTC')

    # Ensure we're passing the access token
    FakeWeb.last_request['Authorization'].should == 'Bearer access_token'
  end

  it "should refresh an expired token" do
    credentials = @credentials.dup
    credentials[:expires_at] = Time.now.to_i - 100
    c = Coinbase::OAuthClient.new 'api key', 'api secret', credentials, @client_options


    token_refresh_response = {
      :access_token => "new_access_token",
      :refresh_token => "new_refresh_token",
      :token_type => "bearer",
      :expires_in => 7200,
    }
    FakeWeb.register_uri(:post, @client_options[:token_url], body: token_refresh_response.to_json, :content_type => "application/json")

    fake :get, '/account/balance', {amount: "50.00000000", currency: 'BTC'}
    c.balance.should == 50.to_money('BTC')

    # Ensure we're passing the new access token
    FakeWeb.last_request['Authorization'].should == 'Bearer new_access_token'

    # Make sure we can retrieve the new credentials for persistance after a refresh
    c.credentials[:refresh_token].should == "new_refresh_token"
  end

  private

  def fake method, path, body
    FakeWeb.register_uri(method, "#{BASE_URI}#{path}", body: body.to_json)
  end

end

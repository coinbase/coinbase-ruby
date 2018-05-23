require 'spec_helper'

describe Coinbase::Wallet::StatusHandler do
  before :all do
    uri = URI.parse("https://api.coinbase.com")
    @conn = Net::HTTP.new(uri.host, uri.port)
  end

  before :each do
    stub_request(:get, /.*/)
      .to_return(body: { warnings: [{ message: 'test' }], errors: [{ id: '404',  message: 'test' }] }.to_json, status: 404)
  end

  describe '.call' do
    it 'handles the response error' do
      # Arrange
      request = Net::HTTP::Get.new('/v2/prices/historic')
      response = Coinbase::Wallet::NetHTTPResponse.new(@conn.request(request))
      status_handler = Coinbase::Wallet::StatusHandler.new(response: response)

      # Act & Assert
      expect { status_handler.call }.to raise_error(Coinbase::Wallet::NotFoundError)
    end
  end

  describe '.check_response_status' do
    it 'handles the response error' do
      # Arrange
      request = Net::HTTP::Get.new('/v2/accounts/primary')
      response = Coinbase::Wallet::NetHTTPResponse.new(@conn.request(request))

      # Act & Assert
      expect {
        Coinbase::Wallet::StatusHandler.check_response_status(response)
      }.to raise_error(Coinbase::Wallet::NotFoundError)
    end
  end
end

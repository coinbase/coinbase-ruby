require 'spec_helper'

describe Coinbase::Wallet::StatusHandler do
  before :all do
    uri = URI.parse("https://api.coinbase.com")
    @conn = Net::HTTP.new(uri.host, uri.port)
  end

  describe '.call' do
    before do
      stub_request(:get, /.*/)
        .to_return(body: { errors: [{ id: '404',  message: 'Not Found' }] }.to_json, status: 404)
    end

    it 'handles response errors' do
      # Arrange
      request = Net::HTTP::Get.new('/v2/prices/historic')
      response = Coinbase::Wallet::NetHTTPResponse.new(@conn.request(request))
      status_handler = Coinbase::Wallet::StatusHandler.new(response: response)

      # Act & Assert
      expect { status_handler.call }.to raise_error(Coinbase::Wallet::NotFoundError)
    end
  end

  describe '.check_response_status' do
    before do
      stub_request(:get, /.*/)
        .to_return(body: { errors: [{ id: '404',  message: 'Not Found' }] }.to_json, status: 404)
    end

    it 'handles response errors' do
      # Arrange
      request = Net::HTTP::Get.new('/v2/accounts/primary')
      response = Coinbase::Wallet::NetHTTPResponse.new(@conn.request(request))

      # Act & Assert
      expect {
        Coinbase::Wallet::StatusHandler.check_response_status(response)
      }.to raise_error(Coinbase::Wallet::NotFoundError)
    end
  end

  describe 'logging' do
    before :each do
      stub_request(:get, /.*/)
        .to_return(body: { warnings: [{ id: "missing_version",
                                        message: "Please supply API version (YYYY-MM-DD) as CB-Version header",
                                        url: "https://developers.coinbase.com/api/v2#versioning"}]
                                      }.to_json, status: 404)
    end

    it 'logs response warnings' do
      # Arrange
      request = Net::HTTP::Get.new('/prices/historic')
      response = Coinbase::Wallet::NetHTTPResponse.new(@conn.request(request))
      status_handler = Coinbase::Wallet::StatusHandler.new(response: response)

      # Act & Assert
      expect { status_handler.call }.to raise_error(Coinbase::Wallet::APIError)
                                    .and output(/Please supply API version/).to_stderr
    end
  end
end

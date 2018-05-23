require 'spec_helper'

describe Coinbase::Wallet::APILogger do
  describe '.warn' do
    before do
      stub_request(:get, /.*/)
        .to_return(body: { warnings: [{ id: "missing_version",
                                        message: "Please supply API version (YYYY-MM-DD) as CB-Version header",
                                        url: "https://developers.coinbase.com/api/v2#versioning"}]
                                      }.to_json, status: 404)
    end

    it 'logs response warnings' do
      # Arrange
      uri = URI.parse("https://api.coinbase.com")
      conn = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new('/prices/historic')
      response = Coinbase::Wallet::NetHTTPResponse.new(conn.request(request))

      # Act & Assert
      expect { described_class.warn(response) }.to output(/WARNING: Please supply API version/).to_stderr
    end
  end
end

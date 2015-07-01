require 'spec_helper'

describe Coinbase::Wallet::Request do
  before :all do
    @object_data = {
      "id" => "2e9f48cd-0b05-5f7c-9056-17a8acb408ad",
      "type" => "request",
      "status" => "pending",
      "amount" => {
        "amount" => "1.00000000",
        "currency" => "BTC"
      },
      "native_amount" => {
        "amount" => "10.00",
        "currency" => "USD"
      },
      "description" => nil,
      "created_at" => "2015-04-01T10:37:11-07:00",
      "updated_at" => "2015-04-01T10:37:11-07:00",
      "resource" => "transaction",
      "resource_path" => "/v2/accounts/2bbf394c-193b-5b2a-9155-3b4732659ede/transactions/2e9f48cd-0b05-5f7c-9056-17a8acb408ad",
      "to" => {
        "resource" => "email",
        "email" => "email@example.com"
      }
    }

    @client = Coinbase::Wallet::Client.new(api_key: 'api_key', api_secret: 'api_secret')
    @object = Coinbase::Wallet::Request.new(@client, @object_data)
  end

  describe '#resend!' do
    it 'should resend an order' do
      stub_request(:post, 'https://api.coinbase.com' + @object_data['resource_path'] + '/resend')
        .to_return(body: { data: mock_item }.to_json)
      expect(@object.resend!).to eq mock_item
    end
  end

  describe '#cancel!' do
    it 'should cancel an order' do
      stub_request(:delete, 'https://api.coinbase.com' + @object_data['resource_path'])
        .to_return(body: { data: mock_item }.to_json)
      expect(@object.cancel!).to eq mock_item
    end
  end
end

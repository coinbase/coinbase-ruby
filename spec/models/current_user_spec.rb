require 'spec_helper'

describe Coinbase::Wallet::CurrentUser do
  before :all do
    @user_data = {
      'id' => '9da7a204-544e-5fd1-9a12-61176c5d4cd8',
      'name' => 'User One',
      'username' => 'user1',
      'profile_location' => nil,
      'profile_bio' => nil,
      'profile_url' => 'https://coinbase.com/user1',
      'avatar_url' => 'https://images.coinbase.com/avatar?h=vR%2FY8igBoPwuwGren5JMwvDNGpURAY%2F0nRIOgH%2FY2Qh%2BQ6nomR3qusA%2Bh6o2%0Af9rH&s=128',
      'resource' => 'user',
      'resource_path' => '/v2/user'
    }

    @client = Coinbase::Wallet::Client.new(api_key: 'api_key', api_secret: 'api_secret')
    @user = Coinbase::Wallet::CurrentUser.new(@client, @user_data)
  end

  describe '#update!' do
    it 'should update new data for object' do
      stub_request(:put, 'https://api.coinbase.com' + @user_data['resource_path'])
        .to_return(body: { data: { name: 'james smith' } }.to_json)
      @user.update!(name: 'james smith')
      expect(@user.name).to eq 'james smith'
    end
  end
end

require 'spec_helper'

describe Coinbase::Wallet::User do
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
      'resource_path' => '/v2/user/9da7a204-544e-5fd1-9a12-61176c5d4cd8'
    }

    @client = Coinbase::Wallet::Client.new(api_key: 'api_key', api_secret: 'api_secret')
    @user = Coinbase::Wallet::User.new(@client, @user_data)
  end

  it 'should access attributes' do
    expect(@user.id).to eq @user_data['id']
  end
end

require 'spec_helper'

describe Coinbase::Wallet::OAuthClient do
  let(:client) { Coinbase::Wallet::OAuthClient.new(access_token: 'access_token', refresh_token: 'refresh_token') }

  it 'handles init with access token and refresh token' do
    stub_request(:get, /.*/)
      .with('headers' => {
          'Authorization' => 'Bearer access_token',
          'CB-VERSION' => Coinbase::Wallet::API_VERSION,
        })
      .to_return(body: { data: { id: 'id', resource: 'user',
                  resource_path: '/v2/user' } }.to_json,
                 status: 200)

    expect { client.current_user }.to_not raise_error
  end

  it 'handles init with access token' do
    stub_request(:get, /.*/)
      .to_return(body: { data: { id: 'id', resource: 'user',
                  resource_path: '/v2/user' } }.to_json,
                 status: 200)

    client = Coinbase::Wallet::OAuthClient.new(access_token: 'access_token')
    expect { client.current_user }.to_not raise_error
  end

  it '#refresh!' do
    body = {
      'access_token' => 'new_access_token',
      'token_type'=> 'bearer',
      'expires_in'=> 7200,
      'refresh_token'=> 'new_refresh_token',
      'scope'=> 'wallet:user:read'
    }

    stub_request(:post, 'https://api.coinbase.com/oauth/token')
      .with(body: {
        grant_type: 'refresh_token',
        refresh_token: 'refresh_token'
        })
      .to_return(body: body.to_json, status: 200)

    expect(client.refresh!).to eq body
    expect(client.access_token).to eq 'new_access_token'
    expect(client.refresh_token).to eq 'new_refresh_token'
  end

  it '#revoke!' do
    stub_request(:post, "https://api.coinbase.com/oauth/revoke")
      .with(body: { token: 'access_token' })
      .to_return(body: mock_item.to_json)
    expect(client.revoke!).to eq mock_item
  end
end
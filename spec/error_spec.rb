require 'spec_helper'

describe Coinbase::Wallet do
  before :all do
    @client = Coinbase::Wallet::Client.new(api_key: 'api_key', api_secret: 'api_secret')
  end

  it "passes" do
    expect(1).to eq(1)
  end

  it "handles param_required" do
    stub_request(:get, /.*/)
      .to_return(body: { errors: [{ id: 'param_required', message: 'test' }] }.to_json,
                 status: 400)
    expect { @client.primary_account }.to raise_error Coinbase::Wallet::ParamRequiredError, "[400] test"
  end

  it "handles invalid_request" do
    stub_request(:get, /.*/)
      .to_return(body: { errors: [{ id: 'invalid_request', message: 'test' }] }.to_json,
                 status: 400)
    expect { @client.primary_account }.to raise_error Coinbase::Wallet::InvalidRequestError, "[400] test"
  end

  it "handles personal_details_required" do
    stub_request(:get, /.*/)
      .to_return(body: { errors: [{ id: 'personal_details_required', message: 'test' }] }.to_json,
                 status: 400)
    expect { @client.primary_account }.to raise_error Coinbase::Wallet::PersonalDetailsRequiredError, "[400] test"
  end

  it "handles obscure 400" do
    stub_request(:get, /.*/)
      .to_return(body: { errors: [{ id: 'obscure_400', message: 'test' }] }.to_json,
                 status: 400)
    expect { @client.primary_account }.to raise_error Coinbase::Wallet::BadRequestError, "[400] test"
  end

  it "handles authentication_error" do
    stub_request(:get, /.*/)
      .to_return(body: { errors: [{ id: 'authentication_error', message: 'test' }] }.to_json,
                 status: 401)
    expect { @client.primary_account }.to raise_error Coinbase::Wallet::AuthenticationError, "[401] test"
  end

  it "handles unverified_email" do
    stub_request(:get, /.*/)
      .to_return(body: { errors: [{ id: 'unverified_email', message: 'test' }] }.to_json,
                 status: 401)
    expect { @client.primary_account }.to raise_error Coinbase::Wallet::UnverifiedEmailError, "[401] test"
  end

  it "handles invalid_token" do
    stub_request(:get, /.*/)
      .to_return(body: { errors: [{ id: 'invalid_token', message: 'test' }] }.to_json,
                 status: 401)
    expect { @client.primary_account }.to raise_error Coinbase::Wallet::InvalidTokenError, "[401] test"
  end

  it "handles revoked_token" do
    stub_request(:get, /.*/)
      .to_return(body: { errors: [{ id: 'revoked_token', message: 'test' }] }.to_json,
                 status: 401)
    expect { @client.primary_account }.to raise_error Coinbase::Wallet::RevokedTokenError, "[401] test"
  end

  it "handles expired_token" do
    stub_request(:get, /.*/)
      .to_return(body: { errors: [{ id: 'expired_token', message: 'test' }] }.to_json,
                 status: 401)
    expect { @client.primary_account }.to raise_error Coinbase::Wallet::ExpiredTokenError, "[401] test"
  end

  it "handles obscure 401" do
    stub_request(:get, /.*/)
      .to_return(body: { errors: [{ id: 'obscure_401', message: 'test' }] }.to_json,
                 status: 401)
    expect { @client.primary_account }.to raise_error Coinbase::Wallet::AuthenticationError, "[401] test"
  end

  it "handles 402" do
    stub_request(:get, /.*/)
      .to_return(body: { errors: [{ id: '402', message: 'test' }] }.to_json,
                 status: 402)
    expect { @client.primary_account }.to raise_error Coinbase::Wallet::TwoFactorRequiredError, "[402] test"
  end

  it "handles 403" do
    stub_request(:get, /.*/)
      .to_return(body: { errors: [{ id: '403', message: 'test' }] }.to_json,
                 status: 403)
    expect { @client.primary_account }.to raise_error Coinbase::Wallet::InvalidScopeError, "[403] test"
  end

  it "handles 404" do
    stub_request(:get, /.*/)
      .to_return(body: { errors: [{ id: '404', message: 'test' }] }.to_json,
                 status: 404)
    expect { @client.primary_account }.to raise_error Coinbase::Wallet::NotFoundError, "[404] test"
  end

  it "handles 422" do
    stub_request(:get, /.*/)
      .to_return(body: { errors: [{ id: '422', message: 'test' }] }.to_json,
                 status: 422)
    expect { @client.primary_account }.to raise_error Coinbase::Wallet::ValidationError, "[422] test"
  end

  it "handles 429" do
    stub_request(:get, /.*/)
      .to_return(body: { errors: [{ id: '429', message: 'test' }] }.to_json,
                 status: 429)
    expect { @client.primary_account }.to raise_error Coinbase::Wallet::RateLimitError, "[429] test"
  end

  it "handles 500" do
    stub_request(:get, /.*/)
      .to_return(body: { errors: [{ id: '500', message: 'test' }] }.to_json,
                 status: 500)
    expect { @client.primary_account }.to raise_error Coinbase::Wallet::InternalServerError, "[500] test"
  end

  it "handles 503" do
    stub_request(:get, /.*/)
      .to_return(body: { errors: [{ id: '503', message: 'test' }] }.to_json,
                 status: 503)
    expect { @client.primary_account }.to raise_error Coinbase::Wallet::ServiceUnavailableError, "[503] test"
  end

  it "handles oauth exception" do
    stub_request(:get, /.*/)
      .to_return(body: { error: "invalid_request", error_description: "test"}.to_json,
                 status: 401)
    expect { @client.primary_account }.to raise_error Coinbase::Wallet::APIError, "[401] test"
  end
end

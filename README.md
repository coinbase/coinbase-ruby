# Coinbase Wallet Gem

This is the official client library for the [Coinbase Wallet API v2](https://developers.coinbase.com/api/v2). We provide an intuitive, stable interface to integrate Coinbase Wallet into your Ruby project.

_Important:_ As this library is targeted for newer API v2, it requires v2 permissions (i.e. `wallet:accounts:read`). If you're still using v1, please use [older version](https://github.com/coinbase/coinbase-ruby/releases/tag/v2.1.1) of this library.

## Installation

Add this line to your application's Gemfile:

    gem 'coinbase'

Then execute:

    bundle install

Or install it yourself as:

    gem install coinbase

## Authentication

### API Key (HMAC Client)

We provide a synchronous client based on Net::HTTP as well as a asynchronous client based on the EM-HTTP-Request gem. For most users, the synchronous client will suffice.

```ruby
require 'coinbase/wallet'
client = Coinbase::Wallet::Client.new(api_key: <api key>, api_secret: <api secret>)
```

The primary intention of the asynchronous client is to integrate nicely with the [Coinbase Exchange Gem](https://github.com/coinbase/coinbase-exchange-ruby). If your project interfaces with our Exchange as well, please consider using this.  *To use this interface, you must include em-http-request gem on your own.*

```ruby
require 'coinbase/wallet'
require 'em-http'

client = Coinbase::Wallet::AsyncClient.new(api_key: <api_key>, api_secret: <api secret>)
```

### OAuth2 Client

We provide an OAuth client if you need access to user accounts other than your own. Currently, the gem does not handle the handshake process, and assumes you have an access token when it's initialized. The OAuth client is synchronous.  Please reach out if you would like us to add an asynchronous OAuth client as well.

```ruby
require 'coinbase/wallet'

# Initializing OAuthClient with both access and refresh token
client = Coinbase::Wallet::OAuthClient.new(access_token: <access token>, refresh_token: <refresh_token>)

# Initializing OAuthClient with only access token
client = Coinbase::Wallet::OAuthClient.new(access_token: <access token>)
```

The OAuth client provides a few extra methods to refresh and revoke the access token.

```ruby
client.refresh!
```

```ruby
client.revoke!
```

_Protip:tm::_ You can test OAuth2 authentication easily with Developer Access Tokens which can be created under your [OAuth2 application settings](https://www.coinbase.com/settings/api). These are short lived tokens which authenticate but don't require full OAuth2 handshake to obtain.

#### Two factor authentication

Send money endpoint requires 2FA token in certain situations (read more [here](https://developers.coinbase.com/docs/wallet/coinbase-connect#two-factor-authentication)). Specific exception is thrown when this is required:

```ruby
account = client.primary_account
begin
  account.send(to: 'test@test.com', amount: '1', currency: "BTC")
rescue Coinbase::Client::TwoFactorRequiredError
  # Show 2FA dialog to user and collect 2FA token

  # Re-try call with `two_factor_token` param
  account.send(to: 'test@test.com', amount: '1', currency: "BTC", two_factor_token: "123456")
end
```

## Requests

We provide one method per API endpoint. Several methods require one or more identifiers to be passed as arguments. Additionally, all parameters can be appended as [keyword arguements](https://robots.thoughtbot.com/ruby-2-keyword-arguments). If a required parameter is not supplied, the client will raise an error. For instance, the following call will send 100 bitcoin to the account registered with example@coinbase.com.

```ruby
account = client.primary_account
account.send(to: 'example@coinbase.com', amount: 100, currency: "USD", description: 'Sending 100 bitcoin')
```

### Pagination

Several endpoints are [paginated](https://developers.coinbase.com/api/v2#pagination). By default, the gem will only fetch the first page of data for a given request. You can implement your own pagination scheme, such as [pipelining](https://en.wikipedia.org/wiki/HTTP_pipelining), by setting the starting_after parameter in your response.

```ruby
client.transactions(account_id) do |data, resp|
  transactions = data
end

more_pages = true
while more_pages
  client.transactions(account_id, starting_after: transactions.last['id']) do |data, resp|
    more_pages = resp.has_more?
    transactions << data
    transactions.flatten!
  end
end
```

If you want to automatically download the entire dataset, you may pass `fetch_all=true` as a parameter.

```ruby
client.transactions(account_id, fetch_all: true) do |data, resp|
  ...
end
```

## Responses

We provide several ways to access return data. Methods will return the data field of the response in hash format.

```ruby
txs = account.transactions(account_id)
txs.each do |tx|
  p tx['id']
end
```

You can also handle data inside a block you pass to the method. **You must access data this way if you're using the asynchronous client.**

```ruby
account.transactions(account_id) do |txs|
  txs.each { |tx| p tx['id'] }
end
```

If you need to access the response metadata (headers, pagination info, etc.) you can access the entire response as the second block paramenter.

```ruby
account.transactions(account_id) do |txs, resp|
  p "STATUS: #{resp.status}"
  p "HEADERS: #{resp.headers}"
  p "BODY: #{resp.body}"
end
```

**Response Object**

The default representation of response data is a JSON hash. However, we further abstract the response to allow access to response fields as though they were methods.

```ruby
account = client.primary_account
p "Account:\t account.name"
p "ID:\t account.id"
p "Balance:\t #{account.balance.amount} #{account.balance.currency}"
```

All values are returned directly from the API unmodified, except the following exceptions:

- [Money amounts](https://developers.coinbase.com/api/v2#money-hash) are always converted into [BigDecimal](http://ruby-doc.org/stdlib-2.1.1/libdoc/bigdecimal/rdoc/BigDecimal.html) objects. You should always use BigDecimal when handing bitcoin amounts for accurate presicion
- [Timestamps](https://developers.coinbase.com/api/v2#timestamps) are always converted into [Time](http://ruby-doc.org/stdlib-2.1.1/libdoc/time/rdoc/Time.html) objects

Most methods require an associated account. Thus, responses for the [account endpoints](https://developers.coinbase.com/api/v2#accounts) contain methods for accessing all the relevant endpoints. This is convient, as it doesn't require you to supply the same account id over and over again.

```ruby
account = client.primary_account
account.send(to: "example@coinbase.com", amount: 100, description: "Sending 100 bitcoin")
```

Alternatively you can pass the account ID straight to the client:

```ruby
client.transactions(<account_id>)
```

Account response objects will automatically update if they detect any changes to the account. The easiest way to refresh an account is to call the refresh! method.

```ruby
account.refresh!
```

### Warnings

It's prudent to be conscious of warnings. By default, the gem will print all warning to STDERR.  If you wish to redirect this stream to somewhere else, such as a log file, then you can simply [change the $stderr global variable](http://stackoverflow.com/questions/4459330/how-do-i-temporarily-redirect-stderr-in-ruby).

### Errors

If the request is not successful, the gem will raise an error. We try to raise a unique error for every possible API response. All errors are subclasses of `Coinbase::Wallet::APIError`.

|Error|Status|
|---|---|
|APIError|*|
|BadRequestError|400|
|ParamRequiredError|400|
|InvalidRequestError|400|
|PersonalDetailsRequiredError|400|
|AuthenticationError|401|
|UnverifiedEmailError|401|
|InvalidTokenError|401|
|RevokedTokenError|401|
|ExpiredTokenError|401|
|TwoFactorRequiredError|402|
|InvalidScopeError|403|
|NotFoundError|404|
|ValidationError|422|
|RateLimitError|429|
|InternalServerError|500|
|ServiceUnavailableError|503|

## Usage

This is not intended to provide complete documentation of the API. For more detail, please refer to the [official documentation](https://developers.coinbase.com/api/v2).

### [Market Data](https://developers.coinbase.com/api/v2#data-api)

**List supported native currencies**

```ruby
client.currencies
```

**List exchange rates**

```ruby
client.exchange_rates
```

**Buy price**

```ruby
client.buy_price
# or
client.buy_price(currency: 'BTC-USD')
```

**Sell price**

```ruby
client.sell_price
# or
client.sell_price(currency: 'ETH-BTC')
```

**Spot price**

```ruby
client.spot_price
# or
client.spot_price(currency: 'BTC-EUR')
```

**Current server time**

```ruby
client.time
```

### [Users](https://developers.coinbase.com/api/v2#users)

**Get authorization info**

```ruby
client.auth_info
```

**Lookup user info**

```ruby
client.user(user_id)
```

**Get current user**

```ruby
client.current_user
```

**Update current user**

```ruby
client.update_current_user(name: "New Name")
```

### [Accounts](https://developers.coinbase.com/api/v2#accounts)

**List all accounts**

```ruby
client.accounts
```

**List account details**

```ruby
client.account(account_id)
```

**List primary account details**

```ruby
client.primary_account
```

**Set account as primary**

```ruby
account.make_primary!
```

**Create a new bitcoin account**

```ruby
client.create_account(name: "New Account")
```

**Update an account**

```ruby
account.update!(name: "New Account Name")
```

**Delete an account**

```ruby
account.delete!
```

### [Addresses](https://developers.coinbase.com/api/v2#addresses)

**List receive addresses for account**

```ruby
account.addresses
```

**Get receive address info**

```ruby
account.address(address_id)
```

**List transactiona for address**

```ruby
account.address_transactions(address_id)
```

**Create a new receive address**

```ruby
account.create_address
```

### [Transactions](https://developers.coinbase.com/api/v2#transactions)

**List transactions**

```ruby
account.transactions
```

**Get transaction info**

```ruby
account.transaction(transaction_id)
```

**Send funds**

```ruby
account.send(to: <bitcoin address>, amount: "5.0", currency: "USD", description: "Your first bitcoin!")
```

**Transfer funds to a new account**

```ruby
account.transfer(to: <account ID>, amount: "1", currency: "BTC", description: "Your first bitcoin!")
```

**Request funds**

```ruby
account.request(to: <email>, amount: "8.0", currency: "USD", description: "Burrito")
```

**Resend request**

```ruby
account.resend_request(request_id)
```

**Cancel request**

```ruby
account.cancel_request(request_id)
```

**Fulfill request**

```ruby
account.complete_request(request_id)
```

### [Buys](https://developers.coinbase.com/api/v2#buys)

**List buys**

```ruby
account.list_buys
```

**Get buy info**

```ruby
account.list_buy(buy_id)
```

**Buy bitcoins**

```ruby
account.buy(amount: "1", currency: "BTC")
```

**Commit a buy**

You only need to do this if you pass `commit=true` when you call the buy method.

```ruby
buy = account.buy(amount: "1", currency: "BTC", commit: false)
account.commit_buy(buy.id)
```

### [Sells](https://developers.coinbase.com/api/v2#sells)

**List sells**

```ruby
account.list_sells
```

**Get sell info**

```ruby
account.list_sell(sell_id)
```

**Sell bitcoins**

```ruby
account.sell(amount: "1", currency: "BTC")
```

**Commit a sell**

You only need to do this if you pass `commit=true` when you call the sell method.

```ruby
sell = account.sell(amount: "1", currency: "BTC", commit: false)
account.commit_sell(sell.id)
```

### [Deposit](https://developers.coinbase.com/api/v2#deposits)

**List deposits**

```ruby
account.list_deposits
```

**Get deposit info**

```ruby
account.list_deposit(deposit_id)
```

**Deposit funds**

```ruby
account.deposit(amount: "10", currency: "USD")
```

**Commit a deposit**

You only need to do this if you pass `commit=true` when you call the deposit method.

```ruby
deposit = account.deposit(amount: "1", currency: "BTC", commit: false)
account.commit_deposit(deposit.id)
```

### [Withdrawals](https://developers.coinbase.com/api/v2#withdrawals)

**List withdrawals**

```ruby
account.list_withdrawals
```

**Get withdrawal**

```ruby
account.list_withdrawal(withdrawal_id)
```

**Withdraw funds**

```ruby
account.withdraw(amount: "10", currency: "USD")
```

**Commit a withdrawal**

You only need to do this if you pass `commit=true` when you call the withdrawal method.

```ruby
withdraw = account.withdraw(amount: "1", currency: "BTC", commit: false)
account.commit_withdrawal(withdrawal.id)
```

### [Payment Methods](https://developers.coinbase.com/api/v2#payment-methods)

**List payment methods**

```ruby
client.payment_methods
```

**Get payment method**

```ruby
client.payment_method(payment_method_id)
```

### [Merchants](https://developers.coinbase.com/api/v2#merchants)

#### Get merchant

```ruby
client.merchant(merchant_id)
```

#### Verify a merchant callback

```ruby
client.verify_callback(request.raw_post, request.headers['CB-SIGNATURE']) # true/false
```

### [Orders](https://developers.coinbase.com/api/v2#orders)

#### List orders

```ruby
client.orders
```

#### Get order

```ruby
client.order(order_id)
```

#### Create order

```ruby
client.create_order(amount: "1", currency: "BTC", name: "Order #1234")
```

#### Refund order

```ruby
order = client.orders.first
order.refund!
```

### Checkouts

#### List checkouts

```ruby
client.checkouts
```

#### Get checkout

```ruby
client.checkout(checkout_id)
```

#### Get checkout's orders

```ruby
checkout = client.checkout(checkout_id)
checkout.orders
```

#### Create order for checkout

```ruby
checkout = client.checkout(checkout_id)
checkout.create_order
```

## Contributing and testing

Any and all contributions are welcome! The process is simple: fork this repo, make your changes, add tests, run the test suite, and submit a pull request. Tests are run via rspec. To run the tests, clone the repository and then:

    # Install the requirements
    gem install coinbase

    # Run tests
    rspec spec

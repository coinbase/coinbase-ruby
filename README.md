# Coinbase

An easy way to buy, send, and accept [bitcoin](http://en.wikipedia.org/wiki/Bitcoin) through the [Coinbase API](https://coinbase.com/docs/api/overview).

This gem is a wrapper around the [Coinbase JSON API](https://developers.coinbase.com/api). It supports both the the [api key + secret authentication method](https://coinbase.com/docs/api/authentication) as well as OAuth 2.0 for performing actions on other people's account.

## Installation

Add this line to your application's Gemfile:

    gem 'coinbase'

Then execute:

    $ bundle install

Or install it yourself as:

    $ gem install coinbase

## Usage

### HMAC Authentication (for accessing your own account)

Start by [enabling an API Key on your account](https://coinbase.com/settings/api)

Next, create an instance of the client and pass it your API Key + Secret as parameters.

```ruby
coinbase = Coinbase::Client.new(ENV['COINBASE_API_KEY'], ENV['COINBASE_API_SECRET'])
```

### OAuth 2.0 Authentication (for accessing others' accounts)

Start by [creating a new OAuth 2.0 application](https://coinbase.com/settings/api)

```ruby
# Obtaining the OAuth credentials is outside the scope of this gem
user_credentials = {
	:access_token => 'access_token',
	:refresh_token => 'refresh_token',
	:expires_at => Time.now + 1.day
}
coinbase = Coinbase::OAuthClient.new(ENV['COINBASE_CLIENT_ID'], ENV['COINBASE_CLIENT_SECRET'], user_credentials)
```

Notice here that we did not hard code the API keys into our codebase, but set it in an environment variable instead. This is just one example, but keeping your credentials separate from your code base is a good [security practice](https://coinbase.com/docs/api/authentication#security).

Now you can call methods on `coinbase` similar to the ones described in the [api reference](https://developers.coinbase.com/api).  For example:

```ruby
coinbase.balance
=> #<Money fractional:20035300000 currency:BTC>
coinbase.balance.format
=> "200.35300000 BTC"
coinbase.balance.to_d
=> #<BigDecimal:7ff36b091670,'0.200353E3',18(54)>
coinbase.balance.to_s
=> 200.35300000 # BTC amount
```

#### Important note on refresh tokens

If :expires_at is included with the user credentials, the client will automatically refresh the credentials when expired. There are two important things to consider when taking advantage of this functionality:

1. You must remember to persist the credentials after you're finished with a client instance, since they may have changed. You can access the most up-to-date credentials by calling .credentials on the client instance. You should do this in an ensure block so that credentials are persisted even after a call that throws an error.
2. In a concurrent environment, you MUST synchronize the use of a given set of credentials. If two threads use the same refresh token, the latter one will fail and, worse, you may persist the old refresh token over the new refresh token and lose all access to the given account.

## Examples

### Check your balance

```ruby
coinbase.balance.to_s
=> "200.35300000" # BTC amount
```

### Send bitcoin

```ruby
r = coinbase.send_money 'user@example.com', 1.23
r.success?
=> true
r.transaction.status
=> 'pending' # this will change to 'complete' in a few seconds if you are sending coinbase-to-coinbase, otherwise it will take about 1 hour, 'complete' means it cannot be reversed or canceled
r.transaction.id
=> '501a1791f8182b2071000087'
r.transaction.recipient.email
=> 'user@example.com'
r.to_hash
=> ... # raw hash response
```

You can also send money in [a number of currencies](https://github.com/coinbase/coinbase-ruby/blob/master/supported_currencies.json).  The amount will be automatically converted to the correct BTC amount using the current exchange rate.

```ruby
r = coinbase.send_money 'user@example.com', 1.23.to_money('AUS')
r.transaction.amount.format
=> "0.06713955 BTC"
```

The first parameter can also be a bitcoin address and the third parameter can be a note or description of the transaction.  Descriptions are only visible on Coinbase (not on the general bitcoin network).

```ruby
r = coinbase.send_money 'mpJKwdmJKYjiyfNo26eRp4j6qGwuUUnw9x', 2.23.to_money("USD"), "thanks for the coffee!"
r.transaction.recipient_address
=> "mpJKwdmJKYjiyfNo26eRp4j6qGwuUUnw9x"
r.transaction.notes
=> "thanks for the coffee!"
```

### Request bitcoin

This will send an email to the recipient, requesting payment, and give them an easy way to pay.

```ruby
r = coinbase.request_money 'client@example.com', 50, "contractor hours in January (website redesign for 50 BTC)"
r.transaction.request?
=> true
r.transaction.id
=> '501a3554f8182b2754000003'
r = coinbase.resend_request '501a3554f8182b2754000003'
r.success?
=> true
r = coinbase.cancel_request '501a3554f8182b2754000003'
r.success?
=> true
# from the other account
r = coinbase.complete_request '501a3554f8182b2754000003'
r.success?
=> true
```

### List your current transactions

Sorted in descending order by timestamp, 30 per page.  You can pass an integer as the first param to page through results, for example `coinbase.transactions(2)`.

```ruby
r = coinbase.transactions
r.current_page
=> 1
r.num_pages
=> 7
r.transactions.collect{|t| t.transaction.id }
=> ["5018f833f8182b129c00002f", "5018f833f8182b129c00002e", ...]
r.transactions.collect{|t| t.transaction.amount.format }
=> ["-1.10000000 BTC", "42.73120000 BTC", ...]
```

Transactions will always have an `id` attribute which is the primary way to identity them through the Coinbase api.  They will also have a `hsh` (bitcoin hash) attribute once they've been broadcast to the network (usually within a few seconds).

### Get transaction details

This will fetch the details/status of a transaction that was made within Coinbase or outside of Coinbase

```ruby
r = coinbase.transaction '5011f33df8182b142400000e'
r.transaction.status
=> 'pending'
r.transaction.recipient_address
=> 'mpJKwdmJKYjiyfNo26eRp4j6qGwuUUnw9x'
```

### Check bitcoin prices

Check the buy or sell price by passing a `quantity` of bitcoin that you'd like to buy or sell. This price includes Coinbase's fee of 1% and the bank transfer fee of $0.15.

The `buy_price` and `sell_price` per Bitcoin will increase and decrease respectively as `quantity` increases. This [slippage](http://en.wikipedia.org/wiki/Slippage_(finance)) is normal and is influenced by the [market depth](http://en.wikipedia.org/wiki/Market_depth) on the exchanges we use.

```ruby
coinbase.buy_price(1).format
=> "$17.95"
coinbase.buy_price(30).format
=> "$539.70"
```


```ruby
coinbase.sell_price(1).format
=> "$17.93"
coinbase.sell_price(30).format
=> "$534.60"
```

Check the spot price of Bitcoin in a given `currency`. This is usually somewhere in between the buy and sell price, current to within a few minutes and does not include any Coinbase or bank transfer fees. The default currency is USD.

```ruby
coinbase.spot_price.format
=> "$431.42"
coinbase.spot_price('EUR').format
=> "€307,40"
```

### Buy or Sell bitcoin

Buying and selling bitcoin requires you to [add a payment method](https://coinbase.com/buys) through the web app first.

Then you can call `buy!` or `sell!` and pass a `quantity` of bitcoin you want to buy (as a float or integer).

```ruby
r = coinbase.buy!(1)
r.transfer.code
=> '6H7GYLXZ'
r.transfer.btc.format
=> "1.00000000 BTC"
r.transfer.total.format
=> "$17.95"
r.transfer.payout_date
=> 2013-02-01 18:00:00 -0800
```


```ruby
r = coinbase.sell!(1)
r.transfer.code
=> 'RD2OC8AL'
r.transfer.btc.format
=> "1.00000000 BTC"
r.transfer.total.format
=> "$17.93"
r.transfer.payout_date
=> 2013-02-01 18:00:00 -0800
```

### Listing Buy/Sell History

You can use `transfers` to view past buys and sells.

```ruby
r = coinbase.transfers
r.current_page
 => 1 
r.total_count
 => 7 
r.transfers.collect{|t| t.transfer.type }
=> ["Buy", "Buy", ...] 
r.transfers.collect{|t| t.transfer.btc.amount }
=> [0.01, 0.01, ...] 
r.transfers.collect{|t| t.transfer.total.amount }
=> [5.72, 8.35, ...] 
```

### Create a payment button

This will create the code for a payment button (and modal window) that you can use to accept bitcoin on your website.  You can read [more about payment buttons here and try a demo](https://coinbase.com/docs/merchant_tools/payment_buttons).

The method signature is `def create_button name, price, description=nil, custom=nil, options={}`.  The `custom` param will get passed through in [callbacks](https://coinbase.com/docs/merchant_tools/callbacks) to your site.  The list of valid `options` [are described here](https://developers.coinbase.com/api#create-a-new-payment-button-page-or-iframe).

```ruby
r = coinbase.create_button "Your Order #1234", 42.95.to_money('EUR'), "1 widget at €42.95", "my custom tracking code for this order"
r.button.code
=> "93865b9cae83706ae59220c013bc0afd"
r.embed_html
=> "<div class=\"coinbase-button\" data-code=\"93865b9cae83706ae59220c013bc0afd\"></div><script src=\"https://coinbase.com/assets/button.js\" type=\"text/javascript\"></script>"
```

### Create an order for a button

This will generate an order associated with a button. You can read [more about creating an order for a button here](https://developers.coinbase.com/api#create-an-order).

```ruby
r = coinbase.create_order_for_button "93865b9cae83706ae59220c013bc0afd"
=> "{\"success\"=>true, \"order\"=>{\"id\"=>\"ASXTKPZM\", \"created_at\"=>\"2013-12-13T01:36:47-08:00\", \"status\"=>\"new\", \"total_btc\"=>{\"cents\"=>6859115, \"currency_iso\"=>\"BTC\"}, \"total_native\"=>{\"cents\"=>4295, \"currency_iso\"=>\"EUR\"}, \"custom\"=>\"my custom tracking code for this order\", \"receive_address\"=>\"mpJKwdmJKYjiyfNo26eRp4j6qGwuUUnw9x\", \"button\"=>{\"type\"=>\"buy_now\", \"name\"=>\"Your Order #1234\", \"description\"=>\"1 widget at 42.95\", \"id\"=>\"93865b9cae83706ae59220c013bc0afd\"}, \"transaction\"=>nil}}"
```

### Create a new user

```ruby
r = coinbase.create_user "newuser@example.com", "some password"
r.user.email
=> "newuser@example.com"
r.receive_address
=> "mpJKwdmJKYjiyfNo26eRp4j6qGwuUUnw9x"
```

A receive address is returned also in case you need to send the new user a payment right away.

You can optionally pass in a client_id parameter that corresponds to your OAuth2 application and an array of permissions. When these are provided, the generated user will automatically have the permissions you’ve specified granted for your application. See the [API Reference](https://developers.coinbase.com/api#create-a-new-user-for-oauth2-application) for more details.

```ruby
r = coinbase.create_user "newuser@example.com", "some password", client_id, ['transactions', 'buy', 'sell']
r.user.email
=> "newuser@example.com"
r.receive_address
=> "mpJKwdmJKYjiyfNo26eRp4j6qGwuUUnw9x"
r.oauth.access_token
=> "93865b9cae83706ae59220c013bc0afd93865b9cae83706ae59220c013bc0afd"
```

## Exchange rates

This gem also extends Money::Bank::VariableExchange with Money::Bank::Coinbase to give you access to Coinbase exchange rates.

### Usage

``` ruby
cb_bank = Money::Bank::Coinbase.new

# Call this before calculating exchange rates
# This will download the rates from CB
cb_bank.fetch_rates!

# Exchange 100 USD to BTC
# API is the same as the money gem
cb_bank.exchange_with(Money.new(10000, :USD), :BTC) # '0.15210000'.to_money(:BTC)

# Set as default bank to do arithmetic and comparisons on Money objects
Money.default_bank = cb_bank
money1 = Money.new(10)
money1.bank # cb_bank

Money.us_dollar(10000).exchange_to(:BTC) # '0.15210000'.to_money(:BTC)
'1'.to_money(:BTC) > '1'.to_money(:USD) # true

# Expire rates after some number of seconds (by default, rates are only updated when you call fetch_rates!)
cb_bank.ttl_in_seconds = 3600 # Cache rates for one hour

# After an hour, different rates
cb_bank.exchange_with(Money.new(10000, :USD), :BTC) # '0.15310000'.to_money(:BTC)

```

## Adding new methods

You can see a [list of method calls here](https://github.com/coinbase/coinbase-ruby/blob/master/lib/coinbase/client.rb) and how they are implemented.  They are a wrapper around the [Coinbase JSON API](https://developers.coinbase.com/api).

If there are any methods listed in the [API Reference](https://developers.coinbase.com/api) that haven't been added to the gem yet, you can also call `get`, `post`, `put`, or `delete` with a `path` and optional `params` hash for a quick implementation.  The raw response will be returned. For example:

```ruby
coinbase.get('/account/balance').to_hash
=> {"amount"=>"50.00000000", "currency"=>"BTC"}
```

Or feel free to add a new wrapper method and submit a pull request.

## Security Notes

If someone gains access to your API Key they will have complete control of your Coinbase account.  This includes the abillity to send all of your bitcoins elsewhere.

For this reason, API access is disabled on all Coinbase accounts by default.  If you decide to enable API key access you should take precautions to store your API key securely in your application.  How to do this is application specific, but it's something you should [research](http://programmers.stackexchange.com/questions/65601/is-it-smart-to-store-application-keys-ids-etc-directly-inside-an-application) if you have never done this before.

## Decimal precision

This gem relies on the [Money](https://github.com/RubyMoney/money) gem, which by default uses the [BigDecimal](www.ruby-doc.org/stdlib-2.0/libdoc/bigdecimal/rdoc/BigDecimal.html) class for arithmetic to maintain decimal precision for all values returned.

When working with currency values in your application, it's important to remember that floating point arithmetic is prone to [rounding errors](http://en.wikipedia.org/wiki/Round-off_error). 

For this reason, we provide examples which use BigDecimal as the preferred way to perform arithmetic:

```coinbase.balance.to_d
=> #<BigDecimal:7ff36b091670,'0.200353E3',18(54)>
```

## Testing

If you'd like to contribute code or modify this gem, you can run the test suite with:

```ruby
gem install coinbase --dev
bundle exec rspec # or just 'rspec' may work
```

## Contributing

1. Fork this repo and make changes in your own copy
2. Add a test if applicable and run the existing tests with `rspec` to make sure they pass
3. Commit your changes and push to your fork `git push origin master`
4. Create a new pull request and submit it back to us!

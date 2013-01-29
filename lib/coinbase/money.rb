curr = {
  :priority        => 1,
  :iso_code        => "BTC",
  :name            => "Bitcoin",
  :symbol          => "BTC",
  :subunit         => "Satoshi",
  :subunit_to_unit => 100000000,
  :separator       => ".",
  :delimiter       => ","
}

Money::Currency.register(curr)
Money.default_currency = Money::Currency.new("BTC")
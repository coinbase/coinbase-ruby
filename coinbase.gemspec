# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'coinbase/wallet/version'

Gem::Specification.new do |gem|
  gem.name          = "coinbase"
  gem.version       = Coinbase::Wallet::VERSION
  gem.authors       = ["John Duhamel"]
  gem.email         = ["jjd@coinbase.com"]
  gem.description   = ["An easy way to buy, send, and accept bitcoin."]
  gem.summary       = ["An easy way to buy, send, and accept bitcoin."]
  gem.homepage      = "https://developers.coinbase.com/api/v2"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|gem|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "bigdecimal"
  gem.add_dependency "em-http-request"

  gem.add_development_dependency "bundler", "~> 1.10"
  gem.add_development_dependency "rake", "~> 10.0"
  gem.add_development_dependency "rgem"
  gem.add_development_dependency "webmock"
  gem.add_development_dependency "timecop"
  gem.add_development_dependency "pry", "~> 0"
end

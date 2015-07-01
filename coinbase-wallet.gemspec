# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'coinbase/wallet/version'

Gem::Specification.new do |spec|
  spec.name          = "coinbase-wallet"
  spec.version       = Coinbase::Wallet::VERSION
  spec.authors       = ["John Duhamel"]
  spec.email         = ["jjd@coinbase.com"]

  spec.summary       = "Client library for Coinbase Wallet API v2"
  spec.homepage      = "https://github.com/coinbase/coinbase-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "bigdecimal"
  spec.add_dependency "em-http-request"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "pry", "~> 0"
end

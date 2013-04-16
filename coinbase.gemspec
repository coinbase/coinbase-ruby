# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'coinbase/version'

Gem::Specification.new do |gem|
  gem.name          = "coinbase"
  gem.version       = Coinbase::VERSION
  gem.authors       = ["Brian Armstrong"]
  gem.email         = [""]
  gem.description   = ["Wrapper for the Coinbase Oauth2 API"]
  gem.summary       = ["Wrapper for the Coinbase Oauth2 API"]
  gem.homepage      = "https://coinbase.com/api/doc"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]


  # Gems that must be intalled for sift to compile and build
  gem.add_development_dependency "rspec", "~> 2.12"
  gem.add_development_dependency "fakeweb", "~> 1.3.0"
  gem.add_development_dependency "rake"

  # Gems that must be intalled for sift to work
  gem.add_dependency "httparty", ">= 0.8.3"
  gem.add_dependency "multi_json", ">= 1.3.4"
  gem.add_dependency "money", ">= 4.0.1"
  gem.add_dependency "hashie", ">= 1.2.0"
end

# -*- encoding: utf-8 -*-
require File.expand_path('../lib/slosilo/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Rafa\305\202 Rzepecki"]
  gem.email         = ["divided.mind@gmail.com"]
  gem.description   = %q{This gem provides an easy way of storing and retrieving encryption keys in the database.}
  gem.summary       = %q{Store SSL keys in a database}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "slosilo"
  gem.require_paths = ["lib"]
  gem.version       = Slosilo::VERSION
  
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'simplecov'
end

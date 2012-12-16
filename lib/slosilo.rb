require "slosilo/version"
require "slosilo/keystore"
require "slosilo/keypair"

Dir[File.join(File.dirname(__FILE__), 'tasks/*.rake')].each { |ext| load ext } if defined?(Rake)

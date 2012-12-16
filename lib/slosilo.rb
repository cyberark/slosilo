require "slosilo/version"
require "slosilo/keystore"
require "slosilo/keypair"

if defined? Sequel
  require 'slosilo/adapters/sequel_adapter'
  Slosilo::adapter = Slosilo::Adapters::SequelAdapter.new
end
Dir[File.join(File.dirname(__FILE__), 'tasks/*.rake')].each { |ext| load ext } if defined?(Rake)

Slosilo::encryption_key = ENV['SLOSILO_KEY']

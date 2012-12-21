require "slosilo/version"
require "slosilo/keystore"
require "slosilo/symmetric"
require "slosilo/attr_encrypted"
require "slosilo/random"
require "slosilo/rack/middleware"
require "slosilo/http_request"

if defined? Sequel
  require 'slosilo/adapters/sequel_adapter'
  Slosilo::adapter = Slosilo::Adapters::SequelAdapter.new
end
Dir[File.join(File.dirname(__FILE__), 'tasks/*.rake')].each { |ext| load ext } if defined?(Rake)

key = ENV['SLOSILO_KEY']
if key
  require 'base64'
  Slosilo::encryption_key = Base64::urlsafe_decode64(key)
end

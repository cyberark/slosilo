require 'openssl'

module Slosilo
  class << self
    def create_keypair name
      Slosilo[name] = OpenSSL::PKey::RSA.new 2048
    end
  end
end

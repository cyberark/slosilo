require 'openssl'

module Slosilo
  class Key
    def initialize raw_key = nil
      @key = if raw_key
        OpenSSL::PKey.read raw_key
      else
        OpenSSL::PKey::RSA.new 2048
      end
    end
    
    attr_reader :key
    
    def cipher
      @cipher ||= Slosilo::Symmetric.new
    end
    
    def encrypt plaintext
      key = cipher.random_key
      ctxt = cipher.encrypt plaintext, key: key
      key = @key.public_encrypt key
      [ctxt, key]
    end
    
    def decrypt ciphertext, skey
      key = @key.private_decrypt skey
      cipher.decrypt ciphertext, key: key
    end
    
    def to_der
      @key.to_der
    end
  end
end

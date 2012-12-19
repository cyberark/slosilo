require 'openssl'
require 'json'
require 'base64'

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
    
    def to_s
      @key.public_key.to_pem
    end
    
    def to_der
      @key.to_der
    end
    
    def sign value
      case value
      when Hash
        sign value.to_a.sort
      when String
        sign_string value
      else
        sign value.to_json
      end
    end

    # create a new timestamped and signed token carrying data
    def signed_token data
      token = { data: data, timestamp: Time.new.utc.to_s }
      token[:signature] = Base64::urlsafe_encode64(sign token)
      token
    end
    
    def sign_string value
      _salt = salt
      key.private_encrypt(hash_function.digest(_salt + value)) + _salt
    end
    
    private
    def salt
      Slosilo::Random::salt
    end
    
    def hash_function
      @hash_function ||= OpenSSL::Digest::SHA256
    end
  end
end

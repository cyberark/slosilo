require 'openssl'
require 'json'
require 'base64'
require 'time'

module Slosilo
  class Key
    def initialize raw_key = nil
      @key = if raw_key
        OpenSSL::PKey.read raw_key rescue raw_key
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
      sign_string(stringify value)
    end
    
    SIGNATURE_LEN = 256
    
    def verify_signature data, signature
      signature, salt = signature.unpack("A#{SIGNATURE_LEN}A*")
      key.public_decrypt(signature) == hash_function.digest(salt + stringify(data))
    end

    # create a new timestamped and signed token carrying data
    def signed_token data
      token = { data: data, timestamp: Time.new.utc.to_s }
      token[:signature] = Base64::urlsafe_encode64(sign token)
      token
    end
    
    def token_valid? token, expiry = 8 * 60
      token = token.clone
      signature = Base64::urlsafe_decode64(token.delete :signature)
      (Time.parse(token[:timestamp]) + expiry > Time.now) && verify_signature(token, signature)
    end
    
    def sign_string value
      _salt = salt
      key.private_encrypt(hash_function.digest(_salt + value)) + _salt
    end
    
    private
    def stringify value
      case value
      when Hash
        value.to_a.sort.to_json
      when String
        value
      else
        value.to_json
      end
    end
    
    def salt
      Slosilo::Random::salt
    end
    
    def hash_function
      @hash_function ||= OpenSSL::Digest::SHA256
    end
  end
end

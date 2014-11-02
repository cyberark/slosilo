require 'openssl'
require 'json'
require 'base64'
require 'time'

module Slosilo
  class Key
    def initialize raw_key = nil
      @key = if raw_key.is_a? OpenSSL::PKey::RSA
        raw_key
      elsif !raw_key.nil?
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
      key = @key.public_encrypt key, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING
      [ctxt, key]
    end

    def encrypt_message plaintext
      c, k = encrypt plaintext
      k + c
    end
    
    def decrypt ciphertext, skey
      key = @key.private_decrypt skey, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING
      cipher.decrypt ciphertext, key: key
    end

    def decrypt_message ciphertext
      k, c = ciphertext.unpack("A256A*")
      decrypt c, k
    end
    
    def to_s
      @key.public_key.to_pem
    end
    
    def to_der
      @to_der ||= @key.to_der
    end
    
    def sign value
      sign_string(stringify value)
    end
    
    SIGNATURE_LEN = 256
    
    def verify_signature data, signature
      signature, salt = signature.unpack("a#{SIGNATURE_LEN}a*")
      key.public_decrypt(signature) == hash_function.digest(salt + stringify(data))
    rescue
      false
    end

    # create a new timestamped and signed token carrying data
    def signed_token data
      token = { "data" => data, "timestamp" => Time.new.utc.to_s }
      token["signature"] = Base64::urlsafe_encode64(sign token)
      token["key"] = fingerprint
      token
    end
    
    def token_valid? token, expiry = 8 * 60
      token = token.clone
      expected_key = token.delete "key"
      return false if (expected_key and (expected_key != fingerprint))
      signature = Base64::urlsafe_decode64(token.delete "signature")
      (Time.parse(token["timestamp"]) + expiry > Time.now) && verify_signature(token, signature)
    end
    
    def sign_string value
      salt = shake_salt
      key.private_encrypt(hash_function.digest(salt + value)) + salt
    end
    
    def fingerprint
      @fingerprint ||= OpenSSL::Digest::MD5.hexdigest key.public_key.to_der
    end

    def == other
      to_der == other.to_der
    end

    alias_method :eql?, :==

    def hash
      to_der.hash
    end

    # return a new key with just the public part of this
    def public
      Key.new(@key.public_key)
    end

    # checks if the keypair contains a private key
    def private?
      @key.private?
    end
    
    private
    
    # Note that this is currently somewhat shallow stringification -- 
    # to implement originating tokens we may need to make it deeper.
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
    
    def shake_salt
      Slosilo::Random::salt
    end
    
    def hash_function
      @hash_function ||= OpenSSL::Digest::SHA256
    end
  end
end

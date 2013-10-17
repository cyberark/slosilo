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
      key = @key.public_encrypt key
      [ctxt, key]
    end

    def encrypt_message plaintext
      c, k = encrypt plaintext
      k + c
    end
    
    def decrypt ciphertext, skey
      key = @key.private_decrypt skey
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

    # create a new timestamped and signed token carrying data.
    # 
    # @param [anything] data data to include in the signed token
    # @param [Hash,nil] options for the signature
    # @option options [see below] :expiration 
    #   Specifies whether to include an `"expiration"` field, and what it's value should be.
    #   The value may be one of:
    #     * `nil`, `true`: Include a default expiration (currently 8 minutes from now).
    #     * `Time`: Set the expiration field to this value
    #     * `Numeric`: Set the token to expire in this many seconds
    #     * `false`: Do not include an expiration field (this is only to support legacy code,
    #         and should not be used for new applications).
    def signed_token data, options = {}
      timestamp, expiration = token_time_fields options
      token = { 
        "data" => data,   
        "timestamp" => timestamp.to_s
      }
      token["expiration"] = expiration.to_s if expiration
      token["signature"] = Base64::urlsafe_encode64(sign token)
      token["key"] = fingerprint
      token
    end
    
    def token_valid? token, expiry = 8 * 60
      token = token.clone
      expected_key = token.delete "key"
      return false if (expected_key and (expected_key != fingerprint))
      signature = Base64::urlsafe_decode64(token.delete "signature")
      !token_expired?(token, expiry) && verify_signature(token, signature)
    end
    
    # Check whether a token is expired, using it's expiration field if present,
    # or the timestamp + :expiry:
    def token_expired? token, expiry = 8 * 60
      if expiration = token["expiration"]
        expiration = Time.parse expiration
      else
        expiration = Time.parse(token["timestamp"]) + expiry
      end
      expiration < current_time
    end
    
    def sign_string value
      _salt = salt
      key.private_encrypt(hash_function.digest(_salt + value)) + _salt
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
    
    def token_time_fields options
      timestamp = current_time
      expiration = case expiration = options[:expiration]
        when FalseClass then nil
        when NilClass, TrueClass then timestamp + 8 * 60
        when Numeric then timestamp + expiration
        when Time then expiration.utc
        else raise ArgumentError, "expiration must be Time or Numeric (was #{expiration} of #{expiration.class})" 
      end
      raise ArgumentError, "Cowardly: refusing to generate already expired token!" if expiration && expiration < timestamp
      [timestamp, expiration]
    end
    
    # Provides a simple way for tests to change the time used
    # when generating and validating tokens.  Use this instead of
    # Time.new/Time.now
    def current_time
      Time.new.utc
    end
  end
end

module Slosilo
  class Key
    def initialize raw_key
      @key = OpenSSL::PKey.read raw_key
    end
    
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
  end
end

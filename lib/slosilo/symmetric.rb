module Slosilo
  class Symmetric
    def initialize
      @cipher = OpenSSL::Cipher.new 'AES-256-CBC'
    end
    
    def encrypt plaintext, opts = {}
      @cipher.reset
      @cipher.encrypt
      @cipher.key = opts[:key]
      @cipher.iv = iv = random_iv
      ctxt = @cipher.update(plaintext)
      iv + ctxt + @cipher.final
    end
    
    def decrypt ciphertext, opts = {}
      @cipher.reset
      @cipher.decrypt
      @cipher.key = opts[:key]
      @cipher.iv, ctxt = ciphertext.unpack("A#{@cipher.iv_len}A*")
      ptxt = @cipher.update(ctxt)
      ptxt + @cipher.final
    end
    
    def random_iv
      @cipher.random_iv
    end
    
    def random_key
      @cipher.random_key
    end
  end
end

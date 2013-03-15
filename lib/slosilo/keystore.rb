require 'slosilo/key'

module Slosilo
  class Keystore
    def adapter 
      Slosilo::adapter or raise "No Slosilo adapter is configured or available"
    end
    
    def put id, key
      adapter.put_key id.to_s, key.to_der
    end
    
    def get id
      key = adapter.get_key(id.to_s)
      key && Key.new(key)
    end
    
    def each &_
      adapter.each { |k, v| yield k, Key.new(v) }
    end
    
    def any? &block
      each do |_, k|
        return true if yield k
      end
      return false
    end
  end
  
  class << self
    def []= id, value
      keystore.put id, value
    end
    
    def [] id
      keystore.get id
    end
    
    def each(&block)
      keystore.each(&block)
    end
    
    def sign object
      self[:own].sign object
    end
    
    def token_valid? token
      keystore.any? { |k| k.token_valid? token }
    end
    
    def token_signer token
      each do |id, key|
        return id if key.token_valid? token
      end
      return nil
    end
    
    attr_accessor :adapter
    
    private
    def keystore
      @keystore ||= Keystore.new
    end
  end
end

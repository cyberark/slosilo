require 'slosilo/key'

module Slosilo
  class Keystore
    def adapter 
      @adapter ||= Slosilo::adapter or raise "No Slosilo adapter is configured or available"
    end
    
    def put id, key
      adapter.put_key id.to_s, key.to_der
    end
    
    def get id
      key = adapter.get_key(id.to_s)
      key && Key.new(key)
    end
    
    def each(&block)
      adapter.each(&block)
    end
    
    def any? &block
      catch :found do
        adapter.each do |id, k|
          throw :found if block.call(Key.new(k))
        end
        return false
      end
      true
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
    
    attr_accessor :adapter
    
    private
    def keystore
      @keystore ||= Keystore.new
    end
  end
end

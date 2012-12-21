require 'slosilo/key'

module Slosilo
  class Keystore
    def adapter 
      @adapter ||= Slosilo::adapter
    end
    
    def put id, key
      adapter.put_key id.to_s, key.to_der
    end
    
    def get id
      Key.new adapter.get_key(id.to_s)
    end
    
    def any? &block
      catch :found do
        adapter.each do |k|
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

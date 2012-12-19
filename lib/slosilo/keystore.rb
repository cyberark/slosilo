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
  end
  
  class << self
    def []= id, value
      keystore.put id, value
    end
    
    def [] id
      keystore.get id
    end
    
    attr_accessor :adapter
    
    private
    def keystore
      @keystore ||= Keystore.new
    end
  end
end

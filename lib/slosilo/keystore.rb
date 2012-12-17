require 'slosilo/key'

module Slosilo
  class << self
    def []= id, value
      adapter.put_key id.to_s, value.to_der
    end
    
    def [] id
      Key.new adapter.get_key(id.to_s)
    end
    
    attr_accessor :adapter
    attr_writer :encryption_key
    
    def encryption_key
      @encryption_key || (raise "Please set Slosilo::encryption_key")
    end
  end
end

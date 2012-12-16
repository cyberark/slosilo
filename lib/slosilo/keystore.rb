module Slosilo
  class << self
    def []= id, value
      adapter.put_key id, value.to_der
    end
    
    attr_accessor :adapter
    attr_writer :encryption_key
    
    def encryption_key
      @encryption_key || (raise "Please set Slosilo::encryption_key")
    end
  end
end

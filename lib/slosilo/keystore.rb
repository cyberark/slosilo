module Slosilo
  class << self
    def []= id, value
      require 'slosilo/model'
      Key.create id: id, key: value.to_der
    end
    
    attr_writer :encryption_key
    
    def encryption_key
      @encryption_key || (raise "Please set Slosilo::encryption_key or SLOSILO_KEY")
    end
  end
end

Slosilo::encryption_key = ENV['SLOSILO_KEY']

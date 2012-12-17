require 'slosilo/attr_encrypted'

module Slosilo
  module Adapters
    class AbstractAdapter
      class StoredKey
        attr_accessor :id, :key
        attr_encrypted :key
        
        def initialize id, key
          self.id = id
          self.key = key
        end
      end
    end
  end
end

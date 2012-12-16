require 'attr_encrypted'

module Slosilo
  module Adapters
    class AbstractAdapter
      class StoredKey
        attr_accessor :id, :encrypted_key
        attr_encrypted :key, key: (proc { Slosilo::encryption_key }), encode: false
        
        def initialize id, key
          self.id = id
          self.key = key
        end
      end
    end
  end
end

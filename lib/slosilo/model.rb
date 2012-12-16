module Slosilo
  class Key < Sequel::Model(:slosilo_keystore)
    require 'attr_encrypted'
    
    unrestrict_primary_key
    attr_encrypted :key, key: (proc { Slosilo::encryption_key }), encode: false
  end
end

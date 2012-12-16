module Slosilo
  class Key < Sequel::Model(:slosilo_keystore)
    unrestrict_primary_key
  end
end

require 'slosilo/adapters/abstract_adapter'

module Slosilo
  module Adapters
    class SequelAdapter < AbstractAdapter
      def model
        @model ||= create_model
      end
      
      def create_model
        model = Sequel::Model(:slosilo_keystore)
        model.unrestrict_primary_key
        model
      end
      
      def put_key id, value
        key = StoredKey.new id, value
        model.create id: key.id, key: key.key
      end
      
      def get_key id
        stored = model[id]
        return nil unless stored
        key = StoredKey.new id, stored.key
        key.key
      end
    end
  end
end

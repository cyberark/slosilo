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
        model.attr_encrypted :key
        model
      end
      
      def put_key id, value
        model.create id: id, key: value
      end
      
      def get_key id
        stored = model[id]
        return nil unless stored
        stored.key
      end
      
      def each
        model.each do |m|
          yield m.key
        end
      end
    end
  end
end

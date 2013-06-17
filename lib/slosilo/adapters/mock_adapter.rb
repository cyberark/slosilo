module Slosilo
  module Adapters
    class MockAdapter < Hash
      def initialize
        @fp = {}
      end

      def put_key id, key
        @fp[key.fingerprint] = key
        self[id] = key
      end

      alias :get_key :[]

      def get_by_fingerprint fp
        @fp[fp]
      end
    end
  end
end

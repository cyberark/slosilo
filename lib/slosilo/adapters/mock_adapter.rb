module Slosilo
  module Adapters
    class MockAdapter < Hash
      alias :put_key :[]=
      alias :get_key :[]
    end
  end
end

module Slosilo
  class Key
    def initialize raw_key
      @key = OpenSSL::PKey.read raw_key
    end
  end
end

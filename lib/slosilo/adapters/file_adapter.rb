require 'slosilo/adapters/abstract_adapter'

module Slosilo
  module Adapters
    class FileAdapter < AbstractAdapter
      attr_reader :dir
      
      def initialize(dir)
        @dir = dir
        @keys = {}
        Dir[File.join(@dir, "*.key")].each do |f|
          key = Slosilo::EncryptedAttributes.decrypt File.read(f)
          @keys[f[@dir.length+1...-4]] = key
        end
      end
      
      def put_key id, value
        fname = File.join(dir, "#{id}.key")
        File.write(fname, Slosilo::EncryptedAttributes.encrypt(value))
        File.chmod(0400, fname)
        @keys[id] = value
      end
      
      def get_key id
        @keys[id]
      end
      
      def each(&block)
        @keys.each(&block)
      end
    end
  end
end

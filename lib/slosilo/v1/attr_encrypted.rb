# require toplevel to make sure the warning is shown
require 'slosilo/v1'

module Slosilo::V1
  # we don't trust the database to keep all backups safe from the prying eyes
  # so we encrypt sensitive attributes before storing them
  module EncryptedAttributes
    module ClassMethods
      def attr_encrypted *a
        # push a module onto the inheritance hierarchy
        # this allows calling super in classes
        include(accessors = Module.new)
        accessors.module_eval do 
          a.each do |attr|
            define_method "#{attr}=" do |value|
              super(EncryptedAttributes.encrypt value)
            end
            define_method attr do
              EncryptedAttributes.decrypt(super())
            end
          end
        end
      end
    end
    
    def self.included base
      base.extend ClassMethods
    end

    class << self
      def encrypt value
        return nil unless value
        cipher.encrypt value, key: key
      end
      
      def decrypt ctxt
        return nil unless ctxt
        cipher.decrypt ctxt, key: key
      end

      def key
        Slosilo::encryption_key || (raise "Please set Slosilo::encryption_key")
      end
      
      def cipher
        @cipher ||= Slosilo::V1::Symmetric.new
      end
    end
  end
end

require 'slosilo/symmetric'

module Slosilo
  # we don't trust the database to keep all backups safe from the prying eyes
  # so we encrypt sensitive attributes before storing them
  module EncryptedAttributes
    module ClassMethods

      # @param options [Hash]
      # @option :aad [Proc-ish] A proc that can be called (instance_eval'd, in point of fact),
      #   to fetch additional authentication data to include when encrypting the attribute.
      #   Generally, you want to use a record id, like this:
      #   ```
      #   attr_encrypted :foo, aad: &:id
      #   ```
      def attr_encrypted *a, options={}
        # push a module onto the inheritance hierarchy
        # this allows calling super in classes
        aad = options[:aad]
        aad_proc = if aad.respond_to?(:to_proc)
           aad.to_proc
        else
          proc{ aad.to_s }
        end
        include(accessors = Module.new)
        accessors.module_eval do 
          a.each do |attr|
            define_method "#{attr}=" do |value|
              super(EncryptedAttributes.encrypt(value, aad: instance_eval(&aad_proc)))
            end
            define_method attr do
              EncryptedAttributes.decrypt(super(), aad: instance_eval(&aad_proc))
            end
          end
        end
      end
    end
    
    def self.included base
      base.extend ClassMethods
    end

    class << self
      def encrypt value, opts={}
        return nil unless value
        cipher.encrypt value, key: key, aad: (options[:aad] || "")
      end
      
      def decrypt ctxt, opts={}
        return nil unless ctxt
        cipher.decrypt ctxt, key: key, aad: (options[:aad] || "")
      end

      def key
        Slosilo::encryption_key || (raise "Please set Slosilo::encryption_key")
      end
      
      def cipher
        @cipher ||= Slosilo::Symmetric.new
      end
    end
  end
  
  class << self
    attr_writer :encryption_key
    
    def encryption_key
      @encryption_key
    end
  end
end

Object.send :include, Slosilo::EncryptedAttributes

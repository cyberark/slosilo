require 'slosilo/symmetric'

module Slosilo
  # we don't trust the database to keep all backups safe from the prying eyes
  # so we encrypt sensitive attributes before storing them
  module EncryptedAttributes
    module ClassMethods

      # @param options [Hash]
      # @option :aad [#to_proc, #to_s]  Provide additional authentication data for
      #   message authentication.  This should be something unique to the instance having
      #   this attribute, such as a primary key.  In particular, you have to be able to recover
      #   it in order to decrypt attributes.  The following values are accepted:
      #
      #   * Something proc-ish: This will be instance_eval'd each time auth data is needed.
      #   * Something non-nil:  This will be to_s'd and used for all instances as auth data.
      #   * nil:  If the class has an instance method #pk, we'll call that to get the auth_data.
      #      Otherwise, we'll use an emmpty string.
      #
      #    The recommended way to use this option is to ommit it, for Sequel models having a primary key.
      #    or pass a symbol for an instance method that can be used as auth data.
      def attr_encrypted *a
        options = a.last.is_a?(Hash) ? a.pop : {}
        aad = options[:aad]
        unless aad.respond_to?(:to_proc)
          aad = lambda { |obj|
            obj.respond_to?(:pk) ? obj.pk : ""
          }
        end
        aad = aad.to_proc
        # push a module onto the inheritance hierarchy
        # this allows calling super in classes

        include(accessors = Module.new)
        accessors.module_eval do 
          a.each do |attr|
            define_method "#{attr}=" do |value|
              super(EncryptedAttributes.encrypt(value, aad: aad[self]))
            end
            define_method attr do
              EncryptedAttributes.decrypt(super(), aad: aad[self])
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
        cipher.encrypt value, key: key, aad: opts[:aad]
      end
      
      def decrypt ctxt, opts={}
        return nil unless ctxt
        cipher.decrypt ctxt, key: key, aad: opts[:aad]
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

require 'slosilo/symmetric'

module Slosilo
  # we don't trust the database to keep all backups safe from the prying eyes
  # so we encrypt sensitive attributes before storing them
  module EncryptedAttributes
    module ClassMethods

      # @param options [Hash]
      # @option :aad [#to_proc, #to_s]  Provide additional authenticated data for
      #   encryption.  This should be something unique to the instance having
      #   this attribute, such as a primary key; this will ensure that an attacker can't swap
      #   values around -- trying to decrypt value with a different auth data will fail.
      #   This means you have to be able to recover it in order to decrypt attributes.
      #   The following values are accepted:
      #
      #   * Something proc-ish: will be called with self each time auth data is needed.
      #   * Something stringish: will be to_s-d and used for all instances as auth data.
      #     Note that this will only prevent swapping in data using another string.
      #
      #   The recommended way to use this option is to pass a proc-ish that identifies the record.
      #   Note the proc-ish can be a simple method name; for example in case of a Sequel::Model:
      #       attr_encrypted :secret, aad: :pk
      def attr_encrypted *a
        options = a.last.is_a?(Hash) ? a.pop : {}
        aad = options[:aad]
        # note nil.to_s is "", which is exactly the right thing
        auth_data = aad.respond_to?(:to_proc) ? aad.to_proc : proc{ |_| aad.to_s }
        raise ":aad proc must take one argument" unless auth_data.arity.abs == 1 # take abs to allow *args arity, -1

        # push a module onto the inheritance hierarchy
        # this allows calling super in classes
        a.each do |attr|
          orig_setter = instance_method "#{attr}="
          define_method "#{attr}=" do |value|
            orig_setter.bind(self)[EncryptedAttributes.encrypt(value, aad: auth_data[self])]
          end
          orig_getter = instance_method attr
          define_method attr do
            EncryptedAttributes.decrypt(orig_getter.bind(self)[], aad: auth_data[self])
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

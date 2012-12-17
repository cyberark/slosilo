require 'sequel'

module Slosilo
  module KeystoreTable
    # The default name of the table to hold the keys
    DEFAULT_KEYSTORE_TABLE = :slosilo_keystore

    # Sets up default keystore table name
    def self.extended(db)
      db.keystore_table ||= DEFAULT_KEYSTORE_TABLE
    end
    
    # Keystore table name. If changing this do it immediately after loading the extension.
    attr_accessor :keystore_table

    # Create the table for holding keys
    def create_keystore_table
      create_table keystore_table do
        String :id, primary_key: true
        # Note: currently only postgres is supported
        bytea :key, null: false
      end
    end
    
    # Drop the table
    def drop_keystore_table
      drop_table keystore_table
    end
  end
  
  module Extension
    def slosilo_keystore
      extend KeystoreTable
    end
  end
  
  Sequel::Database.send:include, Extension
end

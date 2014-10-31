require 'sequel'
require 'slosilo'
require 'slosilo/migration'
module Slosilo

  module Adapters::SequelAdapter::UpdateEncryption
    DEFAULT_KEYSTORE_TABLE = :slosilo_keystore

    attr_writer :keystore_table

    def keystore_table
      @keystore_table ||= DEFAULT_KEYSTORE_TABLE
    end

    def upgrade! db
      before_upgrade! db

      old_cipher = Slosilo::Migration::Symmetric.new
      new_cipher = Slosilo::Symmetric.new
      key = Slosilo::encryption_key || raise("Missing Slosilo::encryption_key!")
      keystore = db[keystore_table]

      progress = progress_bar keystore.count

      keystore.each  do |row|
        ptext = old_cipher.decrypt row[:key], key: key
        ctext = new_cipher.encrypt ptext, key: key, aad: row[:fingerprint]
        keystore.where(fingerprint: row[:fingerprint]).update(key: Sequel.blob(ctext))
        progress.increment
      end
    end

    def before_upgrade! db
      unless db[keystore_table].columns.member?(:fingerprint)
        require 'slosilo/adapters/sequel_adapter/migration'
      end
    end

    def progress_bar count
      begin
        require 'ruby-progressbar'
        ProgressBar.create total: count, output: $stderr, format: '%t |%w>%i| %e'
      rescue LoadError
        Object.new.tap do |o|
          def o.increment; $stderr << '.' end
        end
      end
    end

  end
end

##  Usage
#
# Sequel.migration do
#   up do
#     extend Slosilo::Adapters::SequelAdapter::UpdateEncryption
#     self.keystore_table = :some_custom_table
#     upgrade! self
#   end
#
#   down do
#     raise "Irreversable!"
#   end
# end
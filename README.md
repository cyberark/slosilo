# Slosilo

Slosilo is a keystore in the database. (Currently only works with postgres.)
It allows easy storage and retrieval of keys.

## Installation

Add this line to your application's Gemfile:

    gem 'slosilo'

And then execute:

    $ bundle

Add a migration to create the necessary table:

    require 'slosilo/keystore_table'
    Sequel.migration do
      up do
        slosilo_keystore
        create_keystore_table
      end
      down do
        slosilo_keystore
        drop_keystore_table
      end
    end

Remember to migrate your database

    $ rake db:migrate

## Usage

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

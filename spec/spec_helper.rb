require "simplecov"
SimpleCov.start

require 'slosilo'

require 'slosilo/adapters/mock_adapter'

adapter = Slosilo::adapter = Slosilo::Adapters::MockAdapter.new

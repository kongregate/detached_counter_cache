require 'minitest/autorun'
require 'byebug'

require 'active_record'
ActiveRecord::Base.establish_connection(
  adapter: 'mysql2',
  database: 'detached_counter_cache',
  username: 'root'
)

require 'detached_counter_cache'

require_relative 'lib/schema'
require_relative 'lib/models'

require 'database_cleaner'
DatabaseCleaner.strategy = :transaction

module Minitest
  class Test
    def setup
      DatabaseCleaner.start
    end

    def teardown
      DatabaseCleaner.clean
    end
  end
end

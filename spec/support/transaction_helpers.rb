# frozen_string_literal: true

module TransactionHelpers
  extend ::ActiveSupport::Concern

  def wait_for_thread_warmup(thread)
    thread.run
    5.times do
      sleep 0.1
      break if thread.status.in? [nil, false, 'sleep']
    end
    thread
  end

  def call_once_concurrent_thread
    called_once = false
    proc do |m, *args|
      result = m.call(*args)
      unless called_once
        called_once = true
        concurrent_thread
      end
      result
    end
  end

  def truncate_all_tables
    connection = ActiveRecord::Base.connection
    exclude_table_names = [
      connection.schema_migration.table_name,
      ActiveRecord::InternalMetadata.new(connection).table_name,
      'spatial_ref_sys'
    ]
    connection.truncate_tables(*(connection.tables - exclude_table_names))
    ActiveRecord::FixtureSet.reset_cache
  end

  class_methods do
    def concurrent_transactions_enabled
      around do |example|
        ActiveRecord::Base.connection_pool.lock_thread = false
        Thread.new do
          example.run
          concurrent_thread.join
        ensure
          truncate_all_tables
        end.join
      ensure
        ActiveRecord::Base.connection_pool.lock_thread = true
      end
    end
  end
end

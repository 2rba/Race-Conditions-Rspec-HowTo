class KeyValue < ApplicationRecord
  class << self
    def inc(key)
      transaction do
        record = read_record(key)
        record.update!(value: record.value + 1)
        puts "#{Thread.current.object_id} updated #{record.value}"
      end
    rescue ActiveRecord::RecordNotUnique => e #, ActiveRecord::Deadlocked
      puts "#{Thread.current.object_id} retry #{e}"
      retry
    end

    def read_record(key)
      r = where(key: key).lock(true).first_or_initialize(value: 0)
      puts "#{Thread.current.object_id} read #{r['value']}"
      r
    end
  end
end

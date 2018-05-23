class KeyValue < ApplicationRecord
  class << self
    def inc(key)
      transaction do
        record = read_record(key)
        record.update(value: record.value + 1)
      end
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::Deadlocked
      inc(key)
    end

    def read_record(key)
      where(key: key).lock(true).first_or_initialize(value: 0)
    end
  end
end

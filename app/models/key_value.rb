class KeyValue < ApplicationRecord
  class << self
    def inc(key)
      transaction do
        record = read_record(key)
        record.update(value: record.value + 1)
        p "updated #{record.value}"
      end
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::Deadlocked => e
      p "restart #{e}"
      inc(key)
    end

    def read_record(key)
      r= where(key: key).lock(true).first_or_initialize(value: 0)
      p "readed #{r['value']}"
      r
    end
  end
end

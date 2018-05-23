class ConditionRacer
  include RSpec::Mocks::ExampleMethods

  def initialize(first:, second:, method_name:)
    @first = first
    @second = second
    @method_name = method_name
    @timeout = 5
  end

  def run(&block)
    breakpoint = Mutex.new
    first_mutex = Mutex.new
    second_mutex = Mutex.new

    breakpoint.lock
    set_breakpoints(breakpoint, first_mutex, second_mutex)
    first_thread, second_thread = start_threads(&block)

    Timeout.timeout(@timeout) do
      while !first_mutex.locked? && !second_mutex.locked? do
        sleep 0.1
      end
    end

    breakpoint.unlock
    second_thread.join
    first_thread.join
  end

  private

  def set_breakpoints(breakpoint, first_mutex, second_mutex)
    first_original_method = @first.method(@method_name)
    allow(@first).to receive(@method_name) do |*args|
      result = first_original_method.call(*args)
      first_mutex.lock
      breakpoint.synchronize {}
      first_mutex.unlock
      second_mutex.synchronize {}
      result
    end

    second_original_method = @second.method(@method_name)
    allow(@second).to receive(@method_name) do |*args|
      second_mutex.lock
      breakpoint.synchronize {}
      second_mutex.unlock
      second_original_method.call(*args)
    end
  end

  def start_threads(&block)
    first_thread = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        yield @first
      end
    end

    second_thread = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        yield @second
      end
    end
    [first_thread, second_thread]
  end
end

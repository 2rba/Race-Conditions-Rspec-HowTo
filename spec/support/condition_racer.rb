class ConditionRacer
  include RSpec::Mocks::ExampleMethods

  def initialize(first:, second:, method_name:)
    @first = first
    @second = second
    @method_name = method_name
  end

  def run(&block)
    breakpoint = Mutex.new
    first_mutex = Mutex.new
    second_mutex = Mutex.new

    breakpoint.lock
    set_breakpoints(breakpoint, first_mutex, second_mutex)
    first_thread, second_thread = start_threads(&block)

    #wait till warm up
    wait_till(5, raise_timeout: true) { first_mutex.locked? || second_mutex.locked? }
    #wait till both finished or deadlocked
    wait_till(2) { first_mutex.locked? && second_mutex.locked? }

    breakpoint.unlock
    second_thread.join
    first_thread.join
  end

  private

  def wait_till(time, raise_timeout: false, &block)
    begin
      Timeout.timeout(time) do
        until block.call do
          sleep 0.1
        end
      end
    rescue Timeout::Error => e
      raise e if raise_timeout
    end
  end

  def set_breakpoints(breakpoint, first_mutex, second_mutex)
    first_original_method = @first.method(@method_name)
    allow(@first).to receive(@method_name) do |*args|
      result = first_original_method.call(*args)
      first_mutex.lock
      breakpoint.synchronize {}
      first_mutex.unlock
      result
    end

    second_original_method = @second.method(@method_name)
    allow(@second).to receive(@method_name) do |*args|
      result = second_original_method.call(*args)
      second_mutex.lock
      breakpoint.synchronize {}
      second_mutex.unlock
      result
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

class ConditionRacer
  include RSpec::Mocks::ExampleMethods

  def initialize(first:, second:, method_name:)
    @first = first
    @second = second
    @method_name = method_name
  end

  def run(&block)
    t = nil
    first_original_method = @first.method(@method_name)
    allow(@first).to receive(@method_name) do |*args|
      result = first_original_method.call(*args)

      unless t # tested code may rerun method, so we need race condition case only once
        t = Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            block.call(@second)
          end
        end
        p t.status
        until t.status.in? [nil, false, 'sleep'] do # nil -> exception in thread, false -> not started, sleep -> I/O
          p t.status
          sleep 0.1
        end
      end

      result
    end

    block.call(@first)

    t.join
  end
end

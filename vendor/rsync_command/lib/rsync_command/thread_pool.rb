require 'thread'

class RsyncCommand
  class ThreadPool
    class << self
      attr_accessor :default_size
    end

    def initialize(size=nil)
      @size = size || ThreadPool.default_size || 10
      @jobs = Queue.new
      @retvals = []
      @pool = Array.new(@size) do |i|
        Thread.new do
          Thread.current[:id] = i
          catch(:exit) do
            loop do
              job, args = @jobs.pop
              @retvals << job.call(*args)
            end
          end
        end
      end
    end
    def schedule(*args, &block)
      @jobs << [block, args]
    end
    def shutdown
      @size.times do
        schedule { throw :exit }
      end
      @pool.map(&:join)
      @retvals
    end
  end
end

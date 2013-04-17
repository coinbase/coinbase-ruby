module Coinbase
  class Batch
    MAXIMUM_CONCURRENT_REQUESTS = 10

    def initialize(client, opts={}, &block)
      @client = client
      @commands = []
      @opts = opts

      instance_eval &block
    end

    def run
      responses = []

      until @commands.empty?
        threads = []
        commands = []

        (@opts[:maximum_concurrent_requests] || MAXIMUM_CONCURRENT_REQUESTS).times do
          break if @commands.empty?
          commands << @commands.shift
        end

        commands.each do |c|
          threads << Thread.new {
            Thread.current[:resp] = @client.send c[0], *c[1]
          }
        end

        threads.each {|t| t.join}
        threads.each {|t| responses << t[:resp]}
      end

      responses
    end

    def method_missing(meth, args=[])
      @commands << [meth, args]
    end
  end
end
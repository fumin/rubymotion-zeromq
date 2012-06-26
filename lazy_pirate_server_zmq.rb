#!/Users/mac/.rvm/rubies/ruby-1.9.3-p194/bin/ruby
puts RUBY_VERSION
# Author: Han Holl <han.holl@pobox.com>

require 'rubygems'
#require 'zmq'

require '/Users/mac/Desktop/rubymotion/Hello/ffi-rzmq-OSX/lib/ffi-rzmq.rb'

class LPServer
  def initialize(connect)
    @ctx = ZMQ::Context.new(1)
    @socket = @ctx.socket(ZMQ::REP)
    @socket.bind(connect)
  end

  def run
    begin
      loop do
        rsl = yield @socket.recv
        @socket.send rsl
      end
    ensure
      @socket.close
      @ctx.close
    end
  end
      
end

if $0 == __FILE__
  cycles = 0
  srand
  LPServer.new(ARGV[0] || "tcp://*:5555").run do |request|
    cycles += 1
    if cycles > 3
      if rand(3) == 0
        puts "I: simulating a crash"
        break
      elsif rand(3) == 0
        puts "I: simulating CPU overload"
        sleep(3)
      end
    end
    puts "I: normal request (#{request})"
    sleep(1)
    request
  end
    
end

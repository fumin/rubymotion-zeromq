module Majordomo
  class Broker
    def bind endpoint
      @socket.bind endpoint
puts "I: MDP broker/0.2.0 is active at #{endpoint}"
    end
    def run

    end
    def initialize
      @ctx = zmq_ctx_new
      @socket = ZMQ::Socket.new zmq_socket(@ctx, ZMQ::ROUTER)
      @services = {}
      @workers = {}
      @waiting = []
      @heartbeat_at = Time.now * 1000 + HEARTBEAT_INTERVAL
    end
    def dealloc
      zmq_ctx_destroy @ctx
    end

    private
    def worker_msg sender, msg
      
    end
    def client_msg sender, msg

    end
    def purge

    end

    HEARTBEAT_INTERVAL = 2500
  end # class Broker
end # module Majordomo

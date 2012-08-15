module Majordomo
  class Worker
    def initialize broker, service
      @ctx = zmq_ctx_new
      @broker = broker
      @service = service
      @heartbeat = 2500 # msecs
      @reconnect = 2500 # msecs
      @reply_to = nil
      @poller = ZMQ::Poller.new
      connect_to_broker
    end
    def streamed_recv reply
      # reply ~ [[200, "Content-Length", "300", "Content-Type", "image/png", ...], 
      #          body[0], body[1], ...]
      return recv(nil) if reply.nil?
      send_to_broker(W_REPLY, nil, [@reply_to, ""].concat(reply[0]) << "more")
      reply[1..-2].each do |r|
        send_to_broker(W_REPLY, nil, [@reply_to, "", r, "more"])
        # this is important, because we want to let our broker know that we're alive
        send_to_broker(W_HEARTBEAT, nil, [])
      end
      recv [reply[-1]]
    end
    def recv reply
      send_to_broker(W_REPLY, nil,
                     reply.unshift("").unshift(@reply_to)) if @reply_to && reply
      while true
        if UIApplication.sharedApplication.delegate.should_kill_workers
          @poller.delete @worker
          @worker.close if @worker
          zmq_ctx_destroy @ctx
          return
        end
        @poller.poll @heartbeat
        if @poller.readables.size == 1
          msg = @poller.readables[0].recvmsgs
puts "I: received message #{msg}"
          @liveness = HEARTBEAT_LIVENESS
          return unless msg.size >= 3 && msg[0] == "" && msg[1] == W_WORKER
          command = msg[2]
          case command
          when W_REQUEST
            @reply_to = msg[3]
            return msg[5] # msg[4] is the delimiter ""
          when W_HEARTBEAT
          when W_DISCONNECT
            connect_to_broker
          else
puts "E: invalid input message"
          end
        else
          @liveness -= 1
          if @liveness == 0
puts "W: disconnected from broker - retrying..."
            sleep @reconnect.to_f / 1000
            connect_to_broker
          end
        end
        if Time.now.tv_sec * 1000 > @heartbeat_at
          send_to_broker W_HEARTBEAT, nil, []
          @heartbeat_at = Time.now.tv_sec * 1000 + @heartbeat
        end
      end # while true
    end

    private
    def send_to_broker command, option, msg
      msg.unshift(option) if option
      msg.unshift(command).unshift(W_WORKER).unshift("")
      @worker.sendmsgs msg, 0
    end
    def connect_to_broker
      @poller.delete @worker
      @worker.close if @worker
      @worker = ZMQ::Socket.new zmq_socket(@ctx, ZMQ::DEALER)
      @worker.connect @broker
puts "I: connecting to broker at #{@broker}"
      @poller.register @worker, ZMQ::POLLIN
      send_to_broker W_READY, @service, []
      @liveness = HEARTBEAT_LIVENESS
      @heartbeat_at = Time.now.tv_sec * 1000 + @heartbeat
    end
    HEARTBEAT_LIVENESS = 10 # 3-5 is reasonable
  end # class Worker
end # module Majordomo

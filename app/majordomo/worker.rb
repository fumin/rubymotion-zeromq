module Majordomo
  class Worker
    def initialize broker, service
      @ctx = zmq_ctx_new
      @broker = broker
      @service = service
      @heartbeat = 2500 # msecs
      @reconnect = 2500 # msecs
      @reply_to = nil
      connect_to_broker
      @poller = ZMQ::Poller.new
      @poller.register @worker, ZMQ::POLLIN
    end
    def dealloc
      zmq_ctx_destroy @ctx
    end
    def recv reply
      send_to_broker(W_REPLY, nil, ["", @reply_to, reply]) if @reply_to && reply
      while true
        @poller.poll @heartbeat
        if @poller.readables.size == 1
          msg = @poller.readables[0].recvmsgs
puts "I: received message #{msg.map{|m| m.description}}"
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
        elsif (@liveness -= 1) == 0
puts "W: disconnected from broker - retrying..."
          sleep @reconnect.to_f / 1000
          connect_to_broker
        end
        if Time.now.tv_sec * 1000 > @heartbeat_at
          send_to_broker W_HEARTBEAT, nil, nil
          @heartbeat_at = Time.now.tv_sec * 1000 + @heartbeat
        end
      end # while true
    end

    private
    def send_to_broker command, option, msg
      nsdatas = if msg.is_a?(Array)
                  msg.reverse
                elsif msg.nil?
                  []
                else
                  [msg]
                end
      nsdatas << option if option
      nsdatas << command << W_WORKER << ""
      @worker.sendmsgs nsdatas.reverse
    end
    def connect_to_broker
      @worker.close if @worker
      @worker = ZMQ::Socket.new zmq_socket(@ctx, ZMQ::DEALER)
      @worker.connect @broker
puts "I: connecting to broker at #{@broker}"
      send_to_broker W_READY, @service, nil
      @liveness = HEARTBEAT_LIVENESS
      @heartbeat_at = Time.now.tv_sec * 1000 + @heartbeat
    end
    HEARTBEAT_LIVENESS = 3 # 3-5 is reasonable
  end # class Worker
end # module Majordomo
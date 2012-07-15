module ZMQ
  class Socket
    attr_reader :socket
    def initialize sock
      @socket = sock
    end
    def send msg, flags=0
      p, size = if msg.is_a?(NSData)
                  [msg.bytes, msg.length]
                else
                  [msg.to_data.bytes, msg.size]
                end
      zmq_send @socket, p, size, flags
    end
    def sendmsgs msgs, flags=0
      flags = NonBlocking if dontwait?(flags)
      msgs[0..-2].each do |msg|
        rc = send msg, (flags | SNDMORE)
        return rc unless Util.resultcode_ok?(rc)
      end
      send msgs[-1], flags
    end
    def recv flags=0
      pointer = Pointer.new(Zmq_msg_t_.type)
      zmq_msg_init(zmq_voidify(pointer))
      zmq_recvmsg(@socket, zmq_voidify(pointer), flags)
      to_data = zmq_msg_data(zmq_voidify(pointer))
      size = zmq_msg_size(zmq_voidify(pointer))
      NSData.dataWithBytes(to_data, length:size).to_str
    end
    def recvmsgs flags=0
      datas = []
      datas << recv(flags)
      while getsockopt RCVMORE
        datas << recv(flags)
      end
      datas
    end
    def getsockopt opt
      case opt
      when RCVMORE
        option_value = Pointer.new(:int)
        option_len = Pointer.new(:uint)
        option_len[0] = 4
        zmq_getsockopt @socket, opt, option_value, option_len
        option_value[0] == 0 ? false : true
      end
    end
    def bind addr
      zmq_bind @socket, addr
    end
    def connect addr
      zmq_connect @socket, addr
    end
    def close
      zmq_close @socket
    end
    def dontwait? flags
      (NonBlocking & flags) == NonBlocking
    end
    alias :noblock? :dontwait?
    def dealloc
      close
    end
  end # class Socket
end # module ZMQ

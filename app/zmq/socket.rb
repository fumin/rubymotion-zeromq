module ZMQ
  class Socket
    attr_reader :socket
    def initialize sock
      @socket = sock
    end
    def send msg, flags=0
      if msg.is_a?(String)
        send_str msg, flags
      else
        send_nsdata msg, flags
      end
    end
    def send_str strmsg, flags=0
      send_nsdata strmsg.dataUsingEncoding(NSUTF8StringEncoding), flags
    end
    def send_nsdata nsdata, flags=0
      zmq_send @socket, nsdata.bytes, nsdata.length, flags
    end
    def sendmsgs nsdatas, flags=0
      flags = NonBlocking if dontwait?(flags)
      nsdatas[0..-2].each do |nsdata|
#puts "DEBUG nsdata = #{nsdata.description}"
        rc = send nsdata, (flags | SNDMORE)
        return rc unless Util.resultcode_ok?(rc)
      end
#puts "DEBUG nsdatas[-1] = #{nsdatas[-1].description}"
      send nsdatas[-1], flags
    end
    def recv_nsdata flags=0
      pointer = Pointer.new(Zmq_msg_t_.type)
      zmq_msg_init(zmq_voidify(pointer))
      zmq_recvmsg(@socket, zmq_voidify(pointer), flags)
      to_data = zmq_msg_data(zmq_voidify(pointer))
      size = zmq_msg_size(zmq_voidify(pointer))
      NSData.dataWithBytes(to_data, length:size)
    end
    def recv_str flags=0
      NSString.alloc.initWithData(recv_nsdata(flags), 
        encoding:NSUTF8StringEncoding)
    end
    def recvmsgs flags=0
      datas = []
      datas << recv_nsdata(flags)
      while getsockopt RCVMORE
        datas << recv_nsdata(flags)
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

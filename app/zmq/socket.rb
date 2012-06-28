module ZMQ
  class Socket
    attr_reader :socket
    def initialize sock
      @socket = sock
    end
    def send_str strmsg, flags=0
      send_nsdata strmsg.dataUsingEncoding(NSUTF8StringEncoding), flags
    end
    def send_nsdata nsdata, flags=0
      zmq_send @socket, nsdata.bytes, nsdata.length, flags
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
    def bind addr
      zmq_bind @socket, addr
    end
    def connect addr
      zmq_connect @socket, addr
    end
    def close
      zmq_close @socket
    end
    def dealloc
      close
    end
  end # class Socket
end # module ZMQ

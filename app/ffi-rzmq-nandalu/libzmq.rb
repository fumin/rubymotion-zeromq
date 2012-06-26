module ZMQ
  module LibZMQ
    def zmq_ctx_new
      return zmq_ctx_new #void* context
    end
    def zmq_socket a, b # void* context, int type
      return zmq_socket(a, b)
    end
    def zmq_term a #void* context
      return zmq_term(a)
    end
    def zmq_errno
      return zmq_errno
    end
    def zmq_strerror a #int
      return zmq_strerror(a)
    end
    def zmq_version a, b, c # int* major, int* minor, int* patch
      zmq_version a, b, c
    end

    def zmq_msg_init a # zmq_msg_t*
      return zmq_msg_init a # int
    end
    def zmq_msg_init_size a, b #zmq_msg_t* msg, size_t size
      return zmq_msg_init_size a, b # int
    end
    def zmq_msg_init_data a, b, c, d, e
      # zmq_msg_t* msg, void* data, size_t size, zmq_free_fb* ffn, void* hint
      return zmq_msg_init_data a, b, c, d, e # int
    end
    def zmq_msg_close a # zmq_msg_t*
      return zmq_msg_close a # int
    end
    def zmq_msg_data a # zmq_msg_t*
      return zmq_msg_data a # void*
    end
    def zmq_msg_size a # zmq_msg_t*
      return zmq_msg_size a # size_t
    end
    def zmq_msg_copy a, b # zmq_msg_t* dest, zmq_msg_t* src
      return zmq_msg_copy a, b # int
    end
    def zmq_msg_move a, b # zmq_msg_t* dest, zmq_msg_t* src
      return zmq_msg_move a, b # int
    end

    def zmq_setsockopt a, b, c, d
      # void* socket, int option_name, const void* option_value, size_t option_len
      return zmq_setsockopt a, b, c, d # int
    end
    def zmq_bind a, b # void* socket, const char* endpoint
      return zmq_bind a, b # int
    end
    def zmq_connect a, b # void* socket, const char* endpoint
      return zmq_connect a, b # int
    end
    def zmq_close a # void* socket
      return zmq_close a # int
    end

    def zmq_poll a, b, c 
      # zmq_pollitem_t* items, int nitems, long timeout
      return zmq_poll a, b, c # int
    end

    class PollItem < PollItem_
      def self.type
        PollItem_.type
      end
      def self.sizeof
        pollitem_sizeof
      end
    end
    def zmq_pollitem_memcpy a, b # void* dest, PollItem_ pi
      return zmq_pollitem_memcpy a, b # void
    end

    def zmq_getsockopt a, b, c, d 
      # void* socket, int option_name, void* option_value, size_t* option_len
      return zmq_getsockopt a, b, c, d # int
    end
    def zmq_recvmsg a, b, c # void* socket, zmq_msg_t* msg, int flags
      return zmq_recvmsg a, b, c # int
    end
    def zmq_recv a, b, c, d # void* socket, void* buf, size_t len, int flags
      return zmq_recv a, b, c, d # int
    end
    def zmq_sendmsg a, b, c # void* socket, zmq_msg_t* msg, int flags
      return zmq_sendmsg a, b, c # int
    end
    def zmq_send a, b, c, d # void* socket, void* buf, size_t len, int flags
      return zmq_send a, b, c, d # int
    end
  end # module LibZMQ
end # module ZMQ

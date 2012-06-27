module ZMQ
  class Message
    def self.create message = nil
      new(message) rescue nil
    end

    def initialize message = nil
      @pointer = Pointer.new(:uchar, Message.msg_size)
#      @data_buffer = NSMutableData.alloc.initWithCapacity(0)
      if message
        copy_in_nsdata message
      else
        result_code = LibZMQ.zmq_msg_init @pointer
        raise unless Util.resultcode_ok?(result_code)
      end
    end

    def copy_in_nsdata nsdata
      nsdata_length = nsdata.respond_to?(:length) ? nsdata.length : nsdata.size
 #     @data_buffer.setData(nsdata)
#puts "in Message.copy_in_nsdata: @data_buffer = #{@data_buffer.description}"
#      rc = LibZMQ.zmq_msg_init_data(@pointer, @data_buffer.bytes, nsdata_length, nil, nil)
      rc = LibZMQ.zmq_msg_init_data(@pointer, zmq_create_buffer(nsdata.bytes, nsdata_length), 
                                    nsdata_length, lambda do |data, hint| zmq_free(data, hint) end, nil)
      unless Util.resultcode_ok?(rc)
        puts "in Message.copy_in_nsdata: #{Util.errno}, #{Util.error_string}"
      else
        puts "in Message.copy_in_nsdata: OK, #{rc}"
      end
    end

    def address
      @pointer
    end
    alias :pointer :address

    def copy source
      LibZMQ.zmq_msg_copy @pointer, source
    end

    def move source
      LibZMQ.zmq_msg_move @pointer, source
    end

    def size
      LibZMQ.zmq_msg_size @pointer
    end

    def data
      LibZMQ.zmq_msg_data @pointer
    end

    def copy_out_nsdata
      NSData.alloc.initWithBytes(data, length:size)
    end

    def close
      rc = 0
      if @pointer
        rc = LibZMQ.zmq_msg_close @pointer
        @pointer = nil
      end
      rc
    end
    def self.msg_size
      32 # typedef struct {unsigned char _ [32];} zmq_msg_t;
    end
  end # class Message

end # module ZMQ

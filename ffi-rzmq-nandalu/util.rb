module ZMQ
  class Util
    def self.resultcode_ok? rc
      rc >= 0
    end
    def self.errno
      LibZMQ.zmq_errno
    end
    def self.error_string
      LibZMQ.zmq_strerror(errno)
    end
    def self.version
      major, minor, patch = Pointer.new(:int), Pointer.new(:int), Pointer.new(:int)
      LibZMQ(major, minor, patch)
      return [major, minor, patch]
    end
    def self.error_check source, result_code
      if -1 == result_code
        raise_error source, result_code
      end
      true
    end

    private
    def self.raise_error source, result_code
      if 'zmq_init' == source || 'zmq_socket' == source
        raise ContextError.new source, result_code, 
                ZMQ::Util.errno, ZMQ::Util.error_string
      elsif ['zmq_msg_init', 'zmq_msg_init_data', 
             'zmq_msg_copy', 'zmq_msg_move'].include?(source)
        raise MessageError.new source, result_code, 
                ZMQ::Util.errno, ZMQ::Util.error_string
      else
        puts "else"
        raise ZeroMQError.new source, result_code, -1
                "Source [#{source}] does not match any zmq_* strings, rc [#{result_code}], errno [#{ZMQ::Util.errno}], error_string [#{ZMQ::Util.error_string}]"
      end
    end

  end # class Util

end # module ZMQ

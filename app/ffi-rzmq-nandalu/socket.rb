module ZMQ
  module CommonSocketBehavior
    attr_reader :socket, :name
    
    def setsockopt name, value, length = nil
      if 1 == @option_lookup[name]
        length = 8
        pointer = Pointer.new(:long_long)
        pointer[0] = value
      elsif 0 == @option_lookup[name]
        length = 4
        pointer = Pointer.new(:int)
        pointer[0] = value
      elsif 2 == @option_lookup[name]
        length ||= value.size
        pointer = Pointer.new(:char, length)
        pointer = value
      end
      rc = LibZMQ.zmq_setsockopt(@socket, name, pointer, length)
      pointer = nil unless pointer.nil?
    end

    def more_parts?
      rc = getsockopt ZMQ::RCVMORE, @more_parts_array
      Util.resultcode_ok?(rc) ? @more_parts_array.at(0) : false
    end

    def bind address
      LibZMQ.zmq_bind @socket, address.dataUsingEncoding(NSASCIIStringEncoding).bytes
    end
    
    def connect address
      LibZMQ.zmq_connect @socket, address
    end

    
    def sendmsg message, flags = 0
      rc = __sendmsg__(@socket, message.address, flags)
      unless Util.resultcode_ok?(rc)
        puts "in Socket.sendmsg: #{Util.errno}, #{Util.error_string}"
      else
        puts "in Socket.sendmsg: OK #{rc}"
      end
    end

    def send_nsdata nsdata, flags = 0
      message = Message.new nsdata
      send_and_close message, flags
    end

    def send_nsdatas parts, flags = 0
      return -1 if !parts || parts.empty?
      flags = Nonblocking if dontwait?(flags)
      parts[0..-2].each do |part|
        rc = send_nsdata part, (flags | ZMQ::SNDMORE)
        return rc unless Util.resultcode_ok?(rc)
      end
      send_nsdata parts[-1], flags
    end

    def sendmsgs parts, flags = 0
      return -1 if !parts || parts.empty?
      flags = Nonblocking if dontwait?(flags)
      parts[0..-2].each do |part|
        rc = sendmsg part, (flags | ZMQ::SNDMORE)
        return rc unless Util.resultcode_ok?(rc)
      end
      sendmsg parts[-1], flags
    end

    def send_and_close message, flags = 0
      rc = sendmsg message, flags
      message.close
      rc
    end

    def recvmsg message, flags = 0
      __recvmsg__(@socket, message.address, flags)
    end

    def recv_nsdata flags = 0
      message = @receiver_klass.new
      rc = recvmsg message, flags
      retval = nil
      if Util.resultcode_ok?(rc)
        retval = message.copy_out_nsdata
      end
      message.close
      retval
    end

    def recv_nsdatas flags = 0
      msgs = []
      rc = recvmsgs msgs, flag
      retval = []
      if Util.resultcode_ok?(rc)
        msgs.each do |message|
          retval << message.copy_out_nsdata
          message.close
        end
      end
      retval
    end

    def recvmsgs list, flag = 0
      flag = onBlocking if dontwait?(flag)
      message = @receiver_klass.new
      rc = recvmsg message, flag
      if Util.resultcode_ok?(rc)
        list << message
        while Util.result_code?(rc) && more_parts?
          message = @receiver_klass.new
          rc = recvmsg message, flag
          if Util.resultcode_ok?(rc)
            list << message
          else
            message.close
            list.each{|msg| msg.close}
            list.clear
          end
        end
      else
        message.close
      end
      rc
    end

    def recv_multipart list, routing_envelope, flag = 0
      parts = []
      rc = recvmsgs parts, flag
      if Util.resultcode_ok?(rc)
        routing = true
        parts.each do |part|
          if routing
            routing_envelope << part
            routing = part.size > 0
          else
            list << part
          end
        end
      end
      rc
    end

    def getsockopt name
      option_type = @option_lookup[name]
      value, length = sockopt_buffers option_type
      rc = LibZMQ.zmq_getsockopt @socket, name, value, length
      retval = nil
      if Util.resultcode_ok?(rc)
        if 1 == option_type || 0 == option_type
          retval = value[0]
        else # 2 == option_type
          retval = value
        end
      end
      retval
    end

    private
    def sockopt_buffers option_type
      if 1 == option_type
        unless @longlong_cache
          length = Pointer.new(:char, size_t_sizeof)
          length[0] = 8
          @longlong_cache = [Pointer.new(:long_long), length]
        end
        @longlong_cache
      elsif 0 == option_type
        unless @int_cache
          length = Pointer.new(:uint)
          length[0] = 4
          @int_cache = [Pointer.new(:int), length]
        end
        @int_cache
      elsif 2 == option_type
        length = Pointer.new(:uint)
        length[0] = 255
        [Pointer.new(:char, length), length]
      else
        sockopt_buffers 0
      end
    end

    def common_populate_option_lookup
      [EVENTS, LINGER, RECONNECT_IVL, FD, 
       TYPE, BACKLOG].each{|option| @option_lookup[option] = 0}
      [RCVMORE, AFFINITY].each{|option| @option_lookup[option] = 1}
      [SUBSCRIBE, UNSUBSCRIBE].each{|option| @option_lookup[option] = 2}
    end

    def release_cache
      @longlong_cache = nil
      @int_cache = nil
      @string_cache = nil
    end

    def dontwait?(flags)
      (NonBlocking & flags) == NonBlocking
    end
    alias :noblock? :dontwait?
  end # module CommonSocketBehavior

  module IdentitySupport
    def identity
      getsockopt IDENTITY
    end
    def identity= value
      setsockopt IDENTITY, value.to_s
    end
    def identity_populate_option_lookup
      [IDENTITY].each{|option| @option_lookup[option] = 2}
    end
  end # module IdentitySupport

  class Socket
    include CommonSocketBehavior
    include IdentitySupport
    def self.create context_ptr, type, opts = {receiver_class: ZMQ::Message}
      new(context_ptr, type, opts) rescue nil
    end
    def initialize context_ptr, type, opts = {receiver_class: ZMQ::Message}
      @receiver_klass = opts[:receiver_class]
      context_ptr = context_ptr.pointer if context_ptr.kind_of?(ZMQ::Context)
      unless context_ptr.nil?
        @socket = LibZMQ.zmq_socket context_ptr, type
        if @socket && !@socket.nil?
          @name = SocketTypeNameMap[type]
        else
	  raise ContextError.new 'zmq_socket', 0, ETERM, "Socket pointer was null"
        end
      else
        raise ContextError.new 'zmq_socket', 0, ETERM, "Context pointer was null"
      end

      @longlong_cache = @int_cache = nil
      @more_parts_array = []
      @option_lookup = []
      populate_option_lookup
      common_populate_option_lookup
      identity_populate_option_lookup

      define_finalizer
    end
    def close
      if @socket
        remove_finalizer
        rc = LibZMQ.zmq_close @socket
        @socket = nil
        release_cache
        rc
      else
        0
      end
    end

    private
    def __sendmsg__ socket, address, flags
      LibZMQ.zmq_sendmsg socket, address, flags
    end
    def __recvmsg__ socket, address, flags
      LibZMQ.zmq_recvmsg socket, address, flags
    end
    def populate_option_lookup
      [RECONNECT_IVL_MAX, RCVHWM, SNDHWM, RATE, RECOVERY_IVL, 
       SNDBUF, RCVBUF, IPV4ONLY].each do |option| 
        @option_lookup[option] = 0 
      end
    end
    def define_finalizer
      ObjectSpace.define_finalizer(self, self.class.close(@socket))
    end
    def remove_finalizer
      ObjectSpace.undefine_finalizer self
    end
    def self.close socket
      Proc.new{ LibZMQ.zmq_close socket }
    end
  end # class Socket

end # module ZMQ

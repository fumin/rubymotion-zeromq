module ZMQ
  class Poller
    attr_reader :readables, :writables, :fd_readables, :fd_writables
    def initialize
      @sockets = {}
      @fds = {}
      @buffer = NSMutableData.alloc.initWithCapacity(0)
      @readables = []
      @writables = []
      @fd_readables = []
      @fd_writables = []
    end
    def poll timeout = 0
      prepare_buffer
      zmq_poll(@buffer.bytes, size, timeout)
      update_dables
    end
    def register sock, events = ZMQ::POLLIN | ZMQ::POLLOUT, fd = 0
      return if (!sock.kind_of?(ZMQ::Socket) && fd == 0) || events.zero?
      if sock.kind_of?(ZMQ::Socket)
        @sockets[sock.socket] = PollItem_.new
        @sockets[sock.socket].socket = sock.socket
        @sockets[sock.socket].fd = 0
        @sockets[sock.socket].events |= events
      else
        @fds[fd] = PollItem_.new
        @fds[fd].socket = 0
        @fds[fd].fd = fd
        @fds[fd].events |= events
      end
    end
    def deregister sock, events = ZMQ::POLLIN | ZMQ::POLLOUT

    end
    def delete sock, fd=0
      return unless (sock.kind_of?(ZMQ::Socket) || fd != 0)
      if sock.kind_of?(ZMQ::Socket)
        @sockets.delete sock.socket
      else
        @fds[fd].delete fd
      end
    end
    def size
      @sockets.size + @fds.size
    end

    private
    def prepare_buffer
      @buffer.setLength( size * pollitem_sizeof )
      offset = 0
      p = Pointer.new(PollItem_.type)
      @sockets.each_value do |v|
        p[0] = v
        @buffer.replaceBytesInRange([offset, pollitem_sizeof],
                                    withBytes:p)
        offset += pollitem_sizeof
      end
      @fds.each_value do |v|
        p[0] = v
        @buffer.replaceBytesInRange([offset, pollitem_sizeof],
                                    withBytes:p)
        offset += pollitem_sizeof
      end
    end
    def update_dables
      @readables.clear
      @writables.clear
      @fd_readables.clear
      @fd_writables.clear
      pointer = Pointer.new(PollItem_.type)
      for offset in 0..(size - 1)
        @buffer.getBytes(pointer, 
                         range:[offset * pollitem_sizeof, 
                                pollitem_sizeof])
        p = pointer[0]
        if p.socket != 0
          if p.revents & ZMQ::POLLIN > 0
            @readables << ZMQ::Socket.new(p.socket)
          end
          if p.revents & ZMQ::POLLOUT > 0
            @writables << ZMQ::Socket.new(p.socket)
          end
        else
          if p.revents & ZMQ::POLLIN > 0
            @fd_readables << p.fd
          end
          if p.revents & ZMQ::POLLOUT > 0
            @fd_writables << p.fd
          end
        end
      end
    end
  end # class Poller
end # module ZMQ

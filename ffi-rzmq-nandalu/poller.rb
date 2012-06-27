module ZMQ
  class Poller
    attr_reader :readables, :writables
    def initialize 
      @sockets = {}
      @raw_to_socket = {}
      @readables = []
      @writables = []
      @buffer = NSMutableData.alloc.initWithCapacity(0)
    end
    def poll timeout = :blocking
      unless @sockets.empty?
        prepare_items
pointer = Pointer.new(PollItem_.type)
@buffer.getBytes(pointer, range:[0, 12])
thing = pointer[0]
puts "In POLL0#{loklok(thing.socket)}, #{thing.fd}, #{thing.events}, #{thing.revents}"
        items_triggered = LibZMQ.zmq_poll @buffer.bytes, @sockets.size, timeout
pointer1 = Pointer.new(PollItem_.type)
@buffer.getBytes(pointer1, range:[0, 12])
thing1 = pointer[0]
puts "In POLL1#{loklok(thing1.socket)}, #{thing1.fd}, #{thing1.events}, #{thing1.revents}"
        if Util.resultcode_ok?(items_triggered)
puts "in Poller.poll() => items_triggered = #{items_triggered}"
          update_selectables
        else
puts "We got an error in zmq_poll: #{Util.errno}, #{Util.error_string}"
        end
        items_triggered
      else
        0
      end
    end
    def register sock, events = ZMQ::POLLIN | ZMQ::POLLOUT, fd = 0
      return false if (!sock.kind_of?(ZMQ::Socket) && fd.zero?) || events.zero?
      item = (@sockets[sock.object_id] || @sockets[fd.object_id])
      unless item
        item = LibZMQ::PollItem.new
        item.events |= events
        if sock.kind_of?(ZMQ::Socket)
          item.socket = sock.socket
          item.fd = 0
          @sockets[sock.object_id] = item
          @raw_to_socket[zmq_pointer_to_int(sock.socket)] = sock
        else
          item.socket = 0
          item.fd = fd
          @sockets[fd.object_id] = item
        end
      else
        item.events |= events
      end
    end
    def deregister socket, events, fd = 0
      item = (@sockets[socket.object_id] || @sockets[fd.object_id])
      return false unless item
      return false unless (item.events & events) > 0
      item.events ^= events
      if item.events == 0
        delete socket
        delete fd
      end
      true
    end
    def delete sock
puts "before delete() @sockets = #{@sockets}"
puts "before delete()1 @raw_to_sockets = #{}"
      item = @sockets.delete sock.object_id
      sock_deleted = @raw_to_socket.delete( zmq_pointer_to_int(sock.socket) )
puts "delete() #{item}, @sockets = #{@sockets}"
puts "delete()1 #{sock_deleted}, #{@raw_to_socket}"
      item && sock_deleted
    end
    def register_readable sock
      register sock, ZMQ::POLLIN, 0
    end
    def register_writable sock
      register sock, ZMQ::POLLOUT, 0
    end
    def deregister_readable sock
      deregister sock, ZMQ::POLLIN, 0
    end
    def deregister_writable sock
      deregister sock, ZMQ::POLLOUT, 0
    end
    def size(); @sockets.size; end

    private
    def prepare_items
      @buffer.setLength(@sockets.size * LibZMQ::PollItem.sizeof)
      offset = 0
      #pointer = Pointer.new(LibZMQ::PollItem.type)
      @sockets.each_value do |v|
        zmq_pollitem_memcpy(@buffer.bytes, v)
        #pointer[0] = v
        #@buffer.replaceBytesInRange([offset, LibZMQ::PollItem.sizeof], 
        #                            withBytes: pointer)
        offset += LibZMQ::PollItem.sizeof
      end
    end
    def update_selectables
      @readables.clear
      @writables.clear
      pointer = Pointer.new(LibZMQ::PollItem.type)
      offset = 0
      @sockets.each_value do |unused|
        @buffer.getBytes(pointer, range:[offset, LibZMQ::PollItem.sizeof])
        pollitem = pointer[0]

        if pollitem.revents & ZMQ::POLLIN > 0
          @readables << (@raw_to_socket[zmq_pointer_to_int(pollitem.socket)] || pollitem.fd)
        end
        if pollitem.revents & ZMQ::POLLOUT > 0
          @writables << (@raw_to_socket[zmq_pointer_to_int(pollitem.socket)] || pollitem.fd)
        end
        offset += LibZMQ::PollItem.sizeof
      end
    end
  end # class Poller
end # module ZMA

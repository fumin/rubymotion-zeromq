
class TestViewController < UIViewController

  def viewDidLoad
    puts "viewDidLoad"
    self.navigationItem.rightBarButtonItem = 
      UIBarButtonItem.alloc.initWithTitle:"Join", 
        style:UIBarButtonItemStyleBordered,
        target:self,
        action:'joinChat'
    @photos = NSMutableArray.alloc.initWithCapacity(0)

    @connect = "tcp://localhost:5555"
    @retries = 3
    @timeout = 10
    @ctx = zmq_ctx_new()
    @socket = zmq_socket(@ctx, ZMQ::REQ)
    @testsock = ZMQ::Socket.new(@socket)
    @testsock.connect(@connect)

    @poller = ZMQ::Poller.new
    @poller.register(@testsock, ZMQ::POLLIN)
  end

  def joinChat
    sequence = 0
    retries_left = 3
    while retries_left > 0
      sequence += 1
      @testsock.send_str "#{sequence}"
      received_correct_reply = false
      until received_correct_reply
         @poller.poll 2500
         if @poller.readables.size == 1
           reply = @poller.readables[0].recv_str.to_i
            if reply == sequence
	      puts "I: server replied OK #{sequence}"
	      retries_left = 3
              received_correct_reply = true
	    else
	      puts "E: malformed reply from server: #{reply}, sequence = #{sequence}"
	    end
        else
          retries_left -= 1
          if retries_left == 0
            puts "E: server seems to be offline, abandoning"
            break # we're stoping
          else
            puts "W: no response from server, retrying..."
            @poller.delete @testsock
            @testsock = ZMQ::Socket.new(zmq_socket(@ctx, ZMQ::REQ))
            @testsock.connect(@connect)
            @poller.register @testsock, ZMQ::POLLIN
            @testsock.send_str("#{sequence}")
          end
        end
      end
    end

    # chat client approach
    #@online_session = OnlineSession.alloc.initWithHost:"nandalu.idv.tw", port:7777
    #@online_session.delegate = self
    #@online_session.sendData("\x010004room0002YY".dataUsingEncoding(NSUTF8StringEncoding))
  end

  def find_photos indices
    # photos is an array of NSData*
    @photos.removeAllObjects
    ALAssetsLibrary.alloc.init.enumerateGroupsWithTypes(ALAssetsGroupSavedPhotos,
      usingBlock: lambda do |group, stop|
        break if !group
        group.enumerateAssetsAtIndexes(indices, 
          options:NSEnumerationReverse, 
          usingBlock: lambda do |result, index, stop|
            next if index == NSNotFound || index == -1
            @photos.addObject(UIImageJPEGRepresentation(
	      UIImage.imageWithCGImage(result.defaultRepresentation.fullResolutionImage),
              1.0))
          end
        )
        d = NSMutableData.dataWithCapacity(0)
        d.appendData("\x030004room0002YY".dataUsingEncoding(NSUTF8StringEncoding))
        d.appendData(encode64ToNSData(@photos[0]))
        @online_session.sendData(d)
      end,
      failureBlock: lambda do |err|
        puts err.localizedDescription
      end
    )
  end

  def onlineSession(session, receivedData:data)
    puts "received data..."
    sdata = NSString.alloc.initWithData(data, encoding:NSUTF8StringEncoding)
    puts sdata

    # test server response
    if sdata == "fumin: GET"
      find_photos(intArrayToNSIndexSet([0]))
    end
  end

  def intArrayToNSIndexSet array
    i = NSMutableIndexSet.indexSet
    array.map do |e| 
      return NSMutableIndexSet.indexSet if !e.is_a?(Integer)
      i.addIndex(e)
    end
    return i
  end

  def encode64ToNSData bin
    [bin].pack("m").dataUsingEncoding(NSASCIIStringEncoding)
  end

  def onlineSession(session, encounteredReadError:error)
    puts error
  end

  def onlineSession(session, encounteredWriteError:error)
    puts error
  end

  def sendMessage
    @online_session.sendData("\x0300000004rooma_message")
  end

end


class TestViewController < UIViewController

  def viewDidLoad
    puts "viewDidLoad"
    self.navigationItem.rightBarButtonItem = 
      UIBarButtonItem.alloc.initWithTitle:"Join", 
        style:UIBarButtonItemStyleBordered,
        target:self,
        action:'joinChat'
    @photos = NSMutableArray.alloc.initWithCapacity(0)

    #@connect = "tcp://localhost:5555"
    #@retries = 3
    #@timeout = 10
    #@ctx = zmq_ctx_new()
    #@server = ZMQ::Socket.new(zmq_socket(@ctx, ZMQ::REQ))
    #@server.connect(@connect)
    #@poller = ZMQ::Poller.new
    #@poller.register(@testsock, ZMQ::POLLIN)

    outerQueue = Dispatch::Queue.concurrent(priority=:default)
    outerQueue.async do
      service = get_service "fumin", "0000"
puts "service = #{service}"
      queue = Dispatch::Queue.concurrent(priority=:default)
      1.times{ |i| queue.async{dispatch_majordomo_worker service} }
    end

    request_str = 'GET /books/ctutorial/Building-a-library.html HTTP/1.1
Host: crasseux.com
Connection: keep-alive
Cache-Control: max-age=0
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_4) AppleWebKit/536.11 (KHTML, like Gecko) Chrome/20.0.1132.47 Safari/536.11
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Referer: http://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=7&ved=0CHEQFjAG&url=http%3A%2F%2Fcrasseux.com%2Fbooks%2Fctutorial%2FBuilding-a-library.html&ei=mxnvT8_-Fe3rmAWArPTVDQ&usg=AFQjCNGBkwLNmyDZNoQIBiAc3v7RLMU-Yw
Accept-Encoding: gzip,deflate,sdch
Accept-Language: en-US,en;q=0.8,zh-TW;q=0.6,zh;q=0.4
Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.3
If-None-Match: "145c041-2377-4293ad0c"
If-Modified-Since: Tue, 24 May 2005 22:39:08 GMT

'
  #httpparser = {}
  #@parser = HTTP::HTTPParser.new
  #@parser.execute httpparser, request_str, 0
  #puts "@parser.finished? = #{@parser.finished?}, @parser.error? = #{@parser.error?}"
  #puts httpparser
  end

  def get_service user_name, password
    host = "shop.nandalu.idv.tw"
    #host = "localhost:3000"
    theRequest = NSURLRequest.requestWithURL NSURL.URLWithString("http://#{host}/main/route_login?user_name=#{user_name}&password=#{password}")
    requestError = Pointer.new(:object)
    urlResponse = Pointer.new(:object)
    (NSURLConnection.sendSynchronousRequest(theRequest, returningResponse:urlResponse, error:requestError) || "").to_str
  end

  def dispatch_majordomo_worker service
    worker = Majordomo::Worker.new "tcp://geneva3.godfat.org:5555", service
    reply = nil
    loop do
      request = worker.recv [reply]
      cnatra = Cnatra.new
      reply = cnatra.handle_request(request)
    end
  end

  def joinChat
    cycles = 0
    while 1
      request = @server.recv_str
      cycles += 1;
      if cycles > 3 && rand(120) == 0
        puts "I: simulating a crash"
        break
      elsif cycles > 3 && rand(8) == 0
        puts "I: simulating CPU overload"
        sleep(2)
      else
        puts "I: normal request #{request}"
        sleep(1)
        @server.send_str request
      end
    end
  end

  def client_joinChat
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

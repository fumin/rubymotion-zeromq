class AppDelegate
  attr_accessor :should_kill_workers
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    application.setStatusBarHidden(true, withAnimation:UIStatusBarAnimationFade)
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    @window.rootViewController = UINavigationController.alloc.
                                   initWithRootViewController(TestViewController.alloc.init)
    #@window.rootViewController = MainController.alloc.initWithNibName(nil, bundle: nil)

    # this must be after setting rootViewController, otherwise CRASH
    @window.makeKeyAndVisible
    
    UIApplication.sharedApplication.setIdleTimerDisabled true
    @should_kill_workers = true
    true
  end
  def applicationDidBecomeActive application
    if @should_kill_workers
      @window.rootViewController.viewControllers[0].serverPowerSwitch
    end
  end
  def applicationWillResignActive application
  end
  def applicationDidEnterBackground application
    @bgTask = application.beginBackgroundTaskWithExpirationHandler(lambda do
                application.endBackgroundTask @bgTask
                @bgTask = UIBackgroundTaskInvalid
              end)
  end

  def dispatch_workers
    queue = Dispatch::Queue.concurrent(priority=:default)
    queue.async do
      @current_service = get_service "cardinalblue", "Studio701"
      # @current_service = get_service "fumin", "0000"
puts "@current_service = #{@current_service}"
      WORKERS.times do |i|
        queue.async{ dispatch_majordomo_worker @current_service }
      end
    end
  end

  def get_service user_name, password
    host = "iphone.nandalu.idv.tw"
    #host = "localhost:9292"
    #host = "geneva3.godfat.org:12352"
    theRequest = NSURLRequest.requestWithURL NSURL.URLWithString(
                   "http://#{host}/route_login?user_name=#{user_name}&password=#{password}")
    requestError = Pointer.new(:object); urlResponse = Pointer.new(:object)
    (NSURLConnection.sendSynchronousRequest(theRequest,
      returningResponse:urlResponse, error:requestError) || "").to_str
  end

  def dispatch_majordomo_worker service
    worker = Majordomo::Worker.new "tcp://geneva3.godfat.org:5555", service
    reply = nil
    loop do
      request = worker.streamed_recv reply
puts "!!! WORKER DYING..." if @should_kill_workers
      return if @should_kill_workers
      code, headers, body = Cnatra.new.handle_request(request)
      reply = [[code].concat(headers)].concat( BinData.chunk(body, 200 * 1000) )
              # split into chunks of 200kb
puts "[DEBUG] in loop: reply.size = #{reply.size}"
    end
  end
  WORKERS = 2
end

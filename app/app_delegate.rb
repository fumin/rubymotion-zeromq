class AppDelegate
  attr_reader :current_service
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    application.setStatusBarHidden(true, withAnimation:UIStatusBarAnimationFade)
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    @window.rootViewController = UINavigationController.alloc.initWithRootViewController(TestViewController.alloc.init)
    @window.makeKeyAndVisible
    
    # @window.rootViewController.joinChat
    # @window.rootViewController.sendMessage
    UIApplication.sharedApplication.setIdleTimerDisabled true
    dispatch_workers
    true
  end
  def applicationDidBecomeActive application
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
      @current_service = get_service "fumin", "0000"
puts "@current_service = #{@current_service}"
      WORKERS.times do |i|
        queue.async do
          dispatch_majordomo_worker @current_service
        end
      end
    end
  end
  def get_service user_name, password
    host = "iphone.nandalu.idv.tw"
    #host = "localhost:9292"
    theRequest = NSURLRequest.requestWithURL NSURL.URLWithString("http://#{host}/route_login?user_name=#{user_name}&password=#{password}")
    requestError = Pointer.new(:object)
    urlResponse = Pointer.new(:object)
    (NSURLConnection.sendSynchronousRequest(theRequest, returningResponse:urlResponse, error:requestError) || "").to_str
  end
  def dispatch_majordomo_worker service
    worker = Majordomo::Worker.new "tcp://geneva3.godfat.org:5555", service
    reply = nil
    loop do
      request = worker.streamed_recv reply
      code, headers, body = Cnatra.new.handle_request(request)
      reply = [[code].concat(headers)].concat( BinData.chunk(body, 200 * 1000) )
              # split into chunks of 200kb
puts "[DEBUG] in loop: reply.size = #{reply.size}"
    end
  end
  WORKERS = 2
end

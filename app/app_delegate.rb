class AppDelegate
  attr_accessor :should_kill_workers, :window
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    application.setStatusBarHidden(true, withAnimation:UIStatusBarAnimationFade)
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    #@window.rootViewController = UINavigationController.alloc.
    #                               initWithRootViewController(TestViewController.alloc.init)
    @window.rootViewController = MainController.alloc.initWithNibName(nil, bundle: nil)

    # this must be after setting rootViewController, otherwise CRASH
    @window.makeKeyAndVisible
    
    UIApplication.sharedApplication.setIdleTimerDisabled true
    @should_kill_workers = true
    true
  end
  def applicationDidBecomeActive application
    route = Route.find('me')
    if route
      @window.rootViewController.username_text_field.text = route.username
      @window.rootViewController.password_text_field.text = route.password
    end
    if @should_kill_workers
      @window.rootViewController.power_switch_pressed
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

  def dispatch_workers username, password
    @current_service = get_service username, password
    queue = Dispatch::Queue.concurrent(priority=:default)
    WORKERS.times do |i|
      queue.async{ dispatch_majordomo_worker @current_service }
    end if @current_service && @current_service != WRONG_USERNAME_OR_PASSWORD
    @current_service
  end

  def get_service user_name, password
    host = "iphone.nandalu.idv.tw"
    #host = "localhost:9292"
    #host = "geneva3.godfat.org:12352"
    theRequest = NSURLRequest.requestWithURL NSURL.URLWithString(
                   "http://#{host}/route_login?user_name=#{user_name}&password=#{password}")
    requestError = Pointer.new(:object); urlResponse = Pointer.new(:object)
    data = (NSURLConnection.sendSynchronousRequest(theRequest,
             returningResponse:urlResponse, error:requestError) || "").to_str
puts "route_login data = #{data} #{Time.now}"
    return unless urlResponse[0].statusCode == 200
    return unless /^\w{8}-\w{4}-\w{4}-\w{4}-\w{12}$/ =~ data or
                  WRONG_USERNAME_OR_PASSWORD == data
    data
  end

  def dispatch_majordomo_worker service
    worker = Majordomo::Worker.new "tcp://geneva3.godfat.org:5555", service
    reply = nil
    loop do
      request = worker.streamed_recv reply
      if @should_kill_workers
puts "!!! WORKER DYING..."
        Dispatch::Queue.main.async do
          main_controller.msg_area.text = ""
          UIView.animateWithDuration(1,
            animations:lambda{main_controller.power_switch.alpha = 1})
          main_controller.power_switch_go
        end
        return
      end
      code, headers, body = Cnatra.new.handle_request(request)
      reply = [[code].concat(headers)].concat( BinData.chunk(body, 200 * 1000) )
              # split into chunks of 200kb
puts "[DEBUG] in loop: reply.size = #{reply.size}"
    end
  end

  def main_controller
    @window.rootViewController
  end

  WORKERS = 2
  WRONG_USERNAME_OR_PASSWORD = "wrong username or password"
end

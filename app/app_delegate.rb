class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    UIApplication.sharedApplication.setStatusBarHidden(true, withAnimation:UIStatusBarAnimationFade)
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    @window.rootViewController = UINavigationController.alloc.initWithRootViewController(TestViewController.alloc.init)
    @window.makeKeyAndVisible
    
    # @window.rootViewController.joinChat
    # @window.rootViewController.sendMessage
    true
  end
end

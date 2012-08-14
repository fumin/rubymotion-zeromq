class MainController < UIViewController
  def viewDidLoad
    super
    #self.view.backgroundColor = UIColor.whiteColor

    @username = UITextField.alloc.initWithFrame [[0,0], [160, 26]]
    @username.placeholder = "#abcabc"
    @username.textAlignment = UITextAlignmentCenter
    @username.autocapitalizationType = UITextAutocapitalizationTypeNone
    @username.borderStyle = UITextBorderStyleRoundedRect
    @username.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2 - 200)
    self.view.addSubview @username

    @password = UITextField.alloc.initWithFrame [[0,0], [160, 26]]
    @password.secureTextEntry = YES
    @password.placeholder = "#abcabc"
    @password.textAlignment = UITextAlignmentCenter
    @password.autocapitalizationType = UITextAutocapitalizationTypeNone
    @password.borderStyle = UITextBorderStyleRoundedRect
    @password.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2 - 100)
    self.view.addSubview @password

    @power_switch = UIButton.buttonWithType(UIButtonTypeRoundedRect)
    @power_switch.setTitle("Search", forState:UIControlStateNormal)
    @power_switch.setTitle("Loading", forState:UIControlStateDisabled)
    @power_switch.sizeToFit
    @power_switch.center = CGPointMake(self.view.frame.size.width / 2, @text_field.center.y + 40)
    self.view.addSubview @power_switch
  end
end

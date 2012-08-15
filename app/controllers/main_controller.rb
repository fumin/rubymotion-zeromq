class MainController < UIViewController
  attr_accessor :username_text_field, :password_text_field, :power_switch, :msg_area
  def viewDidLoad
    super
    view_width = self.view.frame.size.width
    view_height = self.view.frame.size.height

    @background_button = UIButton.buttonWithType(UIButtonTypeCustom)
    @background_button.frame = [[0, 0], [view_width, view_height]]
    @background_button.backgroundColor = UIColor.blackColor
    self.view.addSubview @background_button
    @background_button.addTarget(self, action:'background_button_pressed',
                                 forControlEvents:UIControlEventTouchUpInside)

    @logo = UILabel.alloc.initWithFrame([[0, 0], [view_width - 50, view_height / 4]])
    @logo.center = CGPointMake(view_width / 2, view_height / 8 * 2)
    @logo.font = UIFont.fontWithName("American Typewriter", size: 72)
    @logo.textAlignment = UITextAlignmentCenter
    @logo.backgroundColor = UIColor.blackColor
    @logo.textColor = UIColor.whiteColor
    @logo.text = "iServe"
    self.view.addSubview @logo

    @username_text_field = UITextField.alloc.initWithFrame( 
                             [[0,0], [view_width - 50, 45]])
    @username_text_field.delegate = self
    @username_text_field.font = UIFont.systemFontOfSize(32)
    @username_text_field.placeholder = "your email"
    @username_text_field.keyboardType = UIKeyboardTypeEmailAddress
    @username_text_field.returnKeyType = UIReturnKeyNext
    @username_text_field.textAlignment = UITextAlignmentCenter
    @username_text_field.autocapitalizationType = UITextAutocapitalizationTypeNone
    @username_text_field.borderStyle = UITextBorderStyleRoundedRect
    @username_text_field.center = CGPointMake(view_width / 2, view_height / 8 * 3)
    self.view.addSubview @username_text_field

    @password_text_field = UITextField.alloc.initWithFrame(
                             [[0,0], [view_width - 50, 45]])
    @password_text_field.delegate = self
    @password_text_field.secureTextEntry = true
    @password_text_field.font = UIFont.systemFontOfSize(32)
    @password_text_field.placeholder = "your password"
    @password_text_field.returnKeyType = UIReturnKeyGo
    @password_text_field.textAlignment = UITextAlignmentCenter
    @password_text_field.autocapitalizationType = UITextAutocapitalizationTypeNone
    @password_text_field.borderStyle = UITextBorderStyleRoundedRect
    @password_text_field.center = CGPointMake(view_width / 2, view_height / 8 * 4)
    self.view.addSubview @password_text_field

    @power_switch = UIButton.buttonWithType(UIButtonTypeRoundedRect)
    @power_switch.setTitle('go', forState:UIControlStateNormal)
    @power_switch.titleLabel.font = UIFont.systemFontOfSize(32)
    @power_switch.sizeToFit
    button_frame = @power_switch.frame
    button_frame.size = [view_width - 50, button_frame.size.height]
    @power_switch.frame = button_frame
    @power_switch.center = CGPointMake(view_width / 2,
                                       @password_text_field.center.y + 72)
    @power_switch.setBackgroundImage(UIImage.imageNamed("grey.jpeg"),
                                     forState:UIControlStateDisabled)
    self.view.addSubview @power_switch
    @power_switch.addTarget(self, action:'power_switch_pressed',
                            forControlEvents:UIControlEventTouchUpInside)

    @msg_area = UILabel.alloc.initWithFrame([[0, 0], [view_width - 75, view_height / 4]])
    @msg_area.center = CGPointMake(view_width / 2, @power_switch.center.y + 96)
    @msg_area.textAlignment = UITextAlignmentCenter
    @msg_area.backgroundColor = UIColor.blackColor
    @msg_area.textColor = UIColor.whiteColor
    @msg_area.numberOfLines = 0
    self.view.addSubview @msg_area
  end

  def power_switch_pressed
    username = @username_text_field.text
    password = @password_text_field.text
    Route.new(username: username, password: password, id: 'me').save
    if app_delegate.should_kill_workers
      @msg_area.text = "connecting..."
      @power_switch.setTitle('go', forState:UIControlStateDisabled)
      @power_switch.enabled = false
      Dispatch::Queue.concurrent(priority=:default).async do
        resp = app_delegate.dispatch_workers username, password
        if resp
          if resp == 'wrong username or password'
            Dispatch::Queue.main.async do
              @msg_area.text = resp
              @power_switch.setTitle('go', forState:UIControlStateNormal)
              @power_switch.enabled = true
            end
          else
            app_delegate.should_kill_workers = false
            Dispatch::Queue.main.async do
              @msg_area.text =
                "Your personal site\nhttp://iphone.nandalu.idv.tw/#{username}\nis ready!"
              @power_switch.setTitle('stop', forState:UIControlStateNormal)
              @power_switch.enabled = true
            end
          end
        end
      end
    else
      app_delegate.should_kill_workers = true
      @power_switch.setTitle('stop', forState:UIControlStateDisabled)
      @power_switch.enabled = false
      @msg_area.text = "shutting down..."
    end
  end

  def textFieldShouldReturn textField
    case textField
    when @username_text_field
      @password_text_field.becomeFirstResponder
      false
    when @password_text_field
      power_switch_pressed
      false
    else
      true
    end
  end

  def background_button_pressed
    @username_text_field.resignFirstResponder
    @password_text_field.resignFirstResponder
  end

  def app_delegate
    UIApplication.sharedApplication.delegate
  end
end

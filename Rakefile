# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project'

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.name = 'Hello'

  app.vendor_project('vendor/onlinesession', :xcode,
      :products => ["libonlinesession.a"], :headers_dir => 'onlinesession')
  app.frameworks << 'AssetsLibrary' # for direct access of iOS photo library

  #app.vendor_project('vendor/iPhoneSimulator/zeromq-3.2.0', :static,
  #    products: ["build/lib/libzmq.a"], headers_dir: 'build/include')
  app.vendor_project('vendor/iPhoneSimulator/zeromq-3.2.0', :static,
       headers_dir: 'include')


  app.codesign_certificate = 'iPhone Developer: 富民 王 (V6H97ZSMXU)'
  #app.identifier = ''
  app.provisioning_profile = '/Users/mac/Library/MobileDevice/Provisioning Profiles/152BD51D-FB73-481B-8CB5-C1486AF4856B.mobileprovision'

end

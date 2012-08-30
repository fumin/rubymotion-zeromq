# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project'

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.name = 'iServe'

  app.vendor_project('vendor/onlinesession', :xcode,
      :products => ["libonlinesession.a"], :headers_dir => 'onlinesession')
  app.frameworks << 'AssetsLibrary' # for direct access of iOS photo library

  app.vendor_project('vendor/zeromq-3.2.0', :static, headers_dir: 'include')
  app.vendor_project('vendor/zlib-1.2.7', :static, headers_dir: 'include')
  app.icons = ['Icon-114.png', 'Icon-72.png', 'Icon-57.png']

  app.development do
    app.codesign_certificate = 'iPhone Developer: 富民 王 (V6H97ZSMXU)'
    app.identifier = 'com.cardinalblue.iServe'
    app.provisioning_profile = '/Users/mac/Library/MobileDevice/Provisioning Profiles/152BD51D-FB73-481B-8CB5-C1486AF4856B.mobileprovision'
  end

  app.release do
    app.codesign_certificate = 'iPhone Distribution: Cardinal Blue Software, Inc'
    app.identifier = 'com.cardinalblue.iServe'
    #app.provisioning_profile = '/Users/mac/Library/MobileDevice/Provisioning Profiles/A5FDA8B3-DF48-45ED-8151-BFD1954FE503.mobileprovision'

    # for testflight
    # This entitlement is required during development but must not be used for release.
    app.entitlements['get-task-allow'] = false
    # iServe ad hoc
    app.provisioning_profile = '/Users/mac/Library/MobileDevice/Provisioning Profiles/59ACB4D3-EA14-4B62-A5E3-9BCC7A2DEAC3.mobileprovision'
  end

end

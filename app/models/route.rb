class Route < NSUserDefaultsModel
  PROPERTIES = [:current_service_hash, :password, :user_name]
  MANDATORY_PARAMS = [:password, :user_name]

  # rubymotion is lame to have us repeat the below boilerplate code
  PROPERTIES.each { |prop|
    attr_accessor prop
  }
  def properties
    PROPERTIES
  end
end

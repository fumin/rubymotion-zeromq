class Route < NSUserDefaultsModel
  PROPERTIES = [:current_service_hash, :password, :username]
  MANDATORY_PARAMS = [:password, :username]

  # rubymotion is lame to have us repeat the below boilerplate code
  PROPERTIES.each { |prop|
    attr_accessor prop
  }
  def properties
    PROPERTIES
  end
end

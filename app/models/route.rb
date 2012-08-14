class Route < NSUserDefaultsModel
  def properties
    [:current_service_hash, :password, :user_name]
  end
end

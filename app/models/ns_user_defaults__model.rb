class NSUserDefaultsModel
  def properties
    # put an array of properties here
    raise NotImplementedError
  end
  def properties_
    properties + [:id]
  end
  attr_accessor :id
  MANDATORY_PARAMS = []

  def initialize(attributes = {})
    attributes.each { |key, value|
      self.send("#{key}=", value) if properties_.member? key
    }
  end

  def initWithCoder(decoder)
    self.init
    properties_.each { |prop|
      value = decoder.decodeObjectForKey(prop.to_s)
      self.send((prop.to_s + "=").to_s, value) if value
    }
    self
  end

  # called when saving an object to NSUserDefaults
  def encodeWithCoder(encoder)
    properties_.each { |prop|
      encoder.encodeObject(self.send(prop), forKey: prop.to_s)
    }
  end

  def self.find _id
    archived_obj = NSUserDefaults.standardUserDefaults[Route.new.full_id(_id)]
    return unless archived_obj
    NSKeyedUnarchiver.unarchiveObjectWithData(archived_obj)
  end

  def save
    self.class::MANDATORY_PARAMS.each{|p| return unless self.send(p.to_s)}
    return unless id
    NSUserDefaults.standardUserDefaults[full_id(id)] =
      NSKeyedArchiver.archivedDataWithRootObject(self)
    self
  end

  def destroy
    NSUserDefaults.standardUserDefaults.removeObjectForKey( full_id(id) )
    self
  end

  def full_id _id
    "#{self.class.name}.#{_id}"
  end
end

class NSUserDefaultsModel
  def properties
    # put an array of properties here
    raise NotImplementedError
  end
  def properties_
    properties.concat(:id)
  end
  #properties_.each { |prop|
  #  attr_accessor prop
  #}

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

  def defaults
    NSUserDefaults.standardUserDefaults
  end

  def self.find _id
    NSKeyedUnarchiver.unarchiveObjectWithData(defaults[full_id(_id)])
  end

  def save
    defaults[full_id(id)] = NSKeyedArchiver.archivedDataWithRootObject(self)
  end

  def destroy
    defaults.removeObjectForKey( full_id(id) )
  end

  def self.full_id _id
    "#{self.class.name}.#{_id}"
  end
end

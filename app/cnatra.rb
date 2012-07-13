class Cnatra
  def initialize
    @photos = NSMutableArray.alloc.initWithCapacity(0)
  end
  def handle_request request
    m = %r{^/images/(\d+)}.match(request)
    if m
      get_photos([m[1]])[0].to_str
    else
      "404"
    end
  end

  def get_photos int_array
    indices = intArrayToNSIndexSet(int_array.map(&:to_i))
    albumReadLock = NSConditionLock.alloc.initWithCondition 1
    # photos is an array of NSData*
    @photos.removeAllObjects
    ALAssetsLibrary.alloc.init.enumerateGroupsWithTypes(ALAssetsGroupSavedPhotos,
      usingBlock: lambda do |group, stop|
	break if !group
	group.enumerateAssetsAtIndexes(indices,
	  options:NSEnumerationReverse,
	  usingBlock: lambda do |result, index, stop|
	    next if index == NSNotFound || index == -1
	    @photos.addObject(UIImageJPEGRepresentation(
	      UIImage.imageWithCGImage(result.defaultRepresentation.fullResolutionImage),
	      1.0))
	  end
	)
        albumReadLock.lock
        albumReadLock.unlockWithCondition 0
      end,
      failureBlock: lambda do |err|
	puts err.localizedDescription
        albumReadLock.lock
        albumReadLock.unlockWithCondition 0
      end
    )
    # blocks initially because the condition now is 1 and doesn't match 0
    # will resume when the above blocks finish and set the condition to 0
    albumReadLock.lockWhenCondition 0
    albumReadLock.unlock
puts "DEBUGGGGGGGGGGGGGGGG @photos.size = #{@photos.size}"
    @photos
  end

  def intArrayToNSIndexSet array
    i = NSMutableIndexSet.indexSet
    array.map do |e|
      return NSMutableIndexSet.indexSet if !e.is_a?(Integer)
      i.addIndex(e)
    end
    return i
  end
end # class Cnatra

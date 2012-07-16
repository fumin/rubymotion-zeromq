class Cnatra
  def initialize
    @photos = NSMutableArray.alloc.initWithCapacity(0)
  end
  def handle_request request
    m = %r{^/images/(\d+)}.match(request)
    if m
      photo = get_photos([m[1]]).map{|img| uiImage_to_NSData(img, 1024)}[0]
      ["200", ["Content-Length", "#{photo.length}"], photo]
    else
      ["404", [], ""]
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
            representation = result.defaultRepresentation
            uiImage = UIImage.alloc.initWithCGImage(representation.fullResolutionImage,
                                               scale:1.0, orientation:representation.orientation)
            @photos.addObject(uiImage)
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

  def uiImage_to_NSData uiImage, max_dim
    # resize to max width or height with max_dim
    width, height = [uiImage.size.width, uiImage.size.height]
    scale = [(max_dim.to_f / width), (max_dim.to_f / height), 1.0].min
    resized_img = resize_image(uiImage, (width*scale).to_i + 1, (height*scale).to_i + 1)
    NSData.alloc.initWithData(UIImageJPEGRepresentation(resized_img, 1.0))
  end

  def resize_image image, width, height
    imageRef = image.CGImage
    colorSpace = CGColorSpaceCreateDeviceRGB()
    bitmap = CGBitmapContextCreate(nil, width, height, CGImageGetBitsPerComponent(imageRef),
                                   0, CGImageGetColorSpace(imageRef),
                                   KCGImageAlphaPremultipliedFirst)
    transform = CGAffineTransformIdentity
    case image.imageOrientation
    when UIImageOrientationDown
      transform = CGAffineTransformTranslate(transform, width, height)
      transform = CGAffineTransformRotate(transform, M_PI)
    when UIImageOrientationDownMirrored
      transform = CGAffineTransformTranslate(transform, width, height)
      transform = CGAffineTransformRotate(transform, M_PI)
      transform = CGAffineTransformTranslate(transform, width, 0)
      transform = CGAffineTransformScale(transform, -1, 1)
    when UIImageOrientationLeft
      transform = CGAffineTransformTranslate(transform, width, 0)
      transform = CGAffineTransformRotate(transform, M_PI_2)
    when UIImageOrientationLeftMirrored
      transform = CGAffineTransformTranslate(transform, width, 0)
      transform = CGAffineTransformRotate(transform, M_PI_2)
      transform = CGAffineTransformTranslate(transform, height, 0)
      transform = CGAffineTransformScale(transform, -1, 1)
    when UIImageOrientationRight
      transform = CGAffineTransformTranslate(transform, 0, height)
      transform = CGAffineTransformRotate(transform, -M_PI_2)
    when UIImageOrientationRightMirrored
      transform = CGAffineTransformTranslate(transform, 0, height)
      transform = CGAffineTransformRotate(transform, -M_PI_2)
      transform = CGAffineTransformTranslate(transform, height, 0)
      transform = CGAffineTransformScale(transform, -1, 1)
    end
    CGContextConcatCTM(bitmap, transform)
    CGContextDrawImage(bitmap, CGRectMake(0, 0, width, height), imageRef)
    ref = CGBitmapContextCreateImage(bitmap)
    result = UIImage.imageWithCGImage(ref)
    CGContextRelease(bitmap)
    CGImageRelease(ref)
    result
  end

  M_PI = Math::PI
  M_PI_2 = Math::PI / 2
end # class Cnatra

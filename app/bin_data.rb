class BinData
  def self.chunk(myBlob, chunkSize)
    # split blob into chunks where chunk.size <= chunkSize
    return [""] if myBlob.length == 0
    retval = []
    length = myBlob.length
    offset = 0
    while offset < length
      thisChunkSize = length - offset > chunkSize ? chunkSize : length - offset;
      chunk = NSData.dataWithBytesNoCopy myBlob.bytes + offset,
                                         length:thisChunkSize,
                                         freeWhenDone: false
      offset += thisChunkSize
      # do something with chunk
      retval << zlib_deflate(chunk)
      #retval << chunk
    end
    retval
  end
  def self.zlib_deflate nsdata
    out_data = NSMutableData.alloc.initWithLength(nsdata.length)
    ret = zcompress(nsdata.bytes, nsdata.length, out_data.bytes, out_data.length)
    return ret if ret < 0
    out_data.setLength(ret)
puts "[DEBUG] zlib_deflate: out_data.length = #{out_data.length} #{Time.now.strftime("%T")}"
    out_data
  end
end # class BinData

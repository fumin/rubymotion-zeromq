#include "include/z.h"
#include "zlib.h"

int zcompress(unsigned char* in, int in_len, unsigned char* out, int out_len){
  z_stream strm;
  strm.zalloc = Z_NULL;
  strm.zfree = Z_NULL;
  strm.opaque = Z_NULL;
  int ret = deflateInit(&strm, Z_BEST_COMPRESSION);
  if (ret != Z_OK) return ret;
  strm.avail_in = in_len;
  int flush = Z_FINISH;
  strm.next_in = in;
  strm.avail_out = out_len;
  strm.next_out = out;
  ret = deflate(&strm, flush);
  if (ret == Z_STREAM_ERROR) return ret;
  deflateEnd(&strm);
  return out_len - strm.avail_out;
}

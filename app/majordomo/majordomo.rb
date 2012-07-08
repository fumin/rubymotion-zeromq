module Majordomo
  C_CLIENT = "MDPC01" # the version of MDP/client we implement
  W_WORKER = "MDPW01"

  W_READY = "\001".dataUsingEncoding(NSUTF8StringEncoding)
  W_REQUEST = "\002".dataUsingEncoding(NSUTF8StringEncoding)
  W_REPLY = "\003".dataUsingEncoding(NSUTF8StringEncoding)
  W_HEARTBEAT = "\004".dataUsingEncoding(NSUTF8StringEncoding)
  W_DISCONNECT = "\005".dataUsingEncoding(NSUTF8StringEncoding)
end # module Majordomo

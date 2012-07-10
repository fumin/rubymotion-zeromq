module Majordomo
  C_CLIENT = "MDPC01" # the version of MDP/client we implement
  W_WORKER = "MDPW01"

  W_READY = "\001"
  W_REQUEST = "\002"
  W_REPLY = "\003"
  W_HEARTBEAT = "\004"
  W_DISCONNECT = "\005"
end # module Majordomo

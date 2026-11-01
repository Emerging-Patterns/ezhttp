# proofs of laws/ShowReplyOpensWithStatus.bend
import Base
import ../laws/ShowReplyOpensWithStatus.bend as Laws
import ./lemmas/BaseEqualities.bend as M1

def Laws.show_reply_opens_with_status(status, _hs, body):
  M1.eq.starts_append(U32.show(status), " " ++ body)

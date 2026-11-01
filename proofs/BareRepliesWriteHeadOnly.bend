# proofs of laws/BareRepliesWriteHeadOnly.bend
import Base
import ../src/http.bend as Http
import ../laws/BareRepliesWriteHeadOnly.bend as Laws

def Laws.bare_head(_status):
  {==}

def Laws.bare_other(_method, e, status):
  %e : {Bool.or(_, Http.status.nocontent(status)) == Http.status.nocontent(status)
    : Bool}
  {==}

def Laws.nocontent_is(_code):
  {==}

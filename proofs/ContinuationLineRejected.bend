# proofs of laws/ContinuationLineRejected.bend
import Base
import ../src/http.bend as Http
import ../laws/ContinuationLineRejected.bend as Laws

def Laws.head_line_rejects_continuation(_h, e):
  %e : {Http.head.from_cut(_) == None{} : Maybe<&2, Http.Header>}
  {==}

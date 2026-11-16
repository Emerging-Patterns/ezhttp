# proofs of laws/ObsFoldRejected.bend
import Base
import ../src/http.bend as Http
import ../laws/ObsFoldRejected.bend as Laws

def Laws.head_line_rejects_obs_fold(_h, before, after, e, ef):
  %e : {Http.head.from_cut(_) == None{} : Maybe<&2, Http.Header>}
  %ef : {Http.field.keep(before, String.trim(after), _) == None{}
    : Maybe<&2, Http.Header>}
  {==}

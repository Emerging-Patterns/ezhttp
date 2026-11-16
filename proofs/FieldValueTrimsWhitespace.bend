# proofs of laws/FieldValueTrimsWhitespace.bend
import Base
import ../src/http.bend as Http
import ../laws/FieldValueTrimsWhitespace.bend as Laws

def Laws.head_line_trims(_h, before, after, e, ef):
  %e : {Http.head.from_cut(_) == Some{Http.H{before, String.trim(after)}}
    : Maybe<&2, Http.Header>}
  %ef : {Http.field.keep(before, String.trim(after), _)
    == Some{Http.H{before, String.trim(after)}} : Maybe<&2, Http.Header>}
  {==}

# proofs of laws/RequestKeepsFieldNameSpelling.bend
import Base
import ../src/http.bend as Http
import ../laws/RequestKeepsFieldNameSpelling.bend as Laws

def Laws.ask_keeps_field_name_spelling(_h, t, before, after, e, ef):
  %e : {Http.head.cons(Http.head.from_cut(_), Http.head.list(t))
    == Http.H{before, String.trim(after)} <> Http.head.list(t)
    : List<&2, Http.Header>}
  %ef : {Http.head.cons(Http.field.keep(before, String.trim(after), _),
    Http.head.list(t))
    == Http.H{before, String.trim(after)} <> Http.head.list(t)
    : List<&2, Http.Header>}
  {==}

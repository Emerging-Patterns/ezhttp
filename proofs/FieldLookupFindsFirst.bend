# proofs of laws/FieldLookupFindsFirst.bend
import Base
import ../src/http.bend as Http
import ../laws/FieldLookupFindsFirst.bend as Laws

def Laws.headers_find_first(_n, v, t, name, e):
  %e : {Http.headers.find.pick(v, _,
    _u => Http.headers.find.go(t, String.to_lower(name))) == v : String}
  {==}

def Laws.headers_find_skips(_n, v, t, name, e):
  %e : {Http.headers.find.pick(v, _,
    _u => Http.headers.find.go(t, String.to_lower(name)))
    == Http.headers.find(t, name) : String}
  {==}

# proofs of laws/PhraseTableLookup.bend
import Base
import ../src/http.bend as Http
import ../laws/PhraseTableLookup.bend as Laws

def Laws.reason_in_nil(_code):
  {==}

def Laws.reason_in_hit(code, _c, text, t, e):
  %e : {Http.reason.pick(text, _, _u => Http.reason.in(t, code)) == text
    : String}
  {==}

def Laws.reason_in_miss(code, _c, text, t, e):
  %e : {Http.reason.pick(text, _, _u => Http.reason.in(t, code))
    == Http.reason.in(t, code) : String}
  {==}

# proofs of laws/RequestEqualContentLengthsFrameOneBody.bend
import Base
import ../src/http.bend as Http
import ../laws/RequestEqualContentLengthsFrameOneBody.bend as Laws

def Laws.clen_agree_repeat(v, _w, rest, e):
  %e : {Http.clen.agree.step(_, _u => Http.clen.agree.go(rest, v))
    == Http.clen.agree.go(rest, v) : Bool}
  {==}

def Laws.ask_equal_content_lengths(method, target, hs, te, lens, body, ea, ec):
  %ea : {Http.ask.agree(method, target, hs, te, lens, body, _)
    == Http.ask.len(method, target, hs, Http.digits.read(Http.first(lens)),
      body) : Http.Request}
  %ec : {Http.ask.te(method, target, hs, lens, body, _)
    == Http.ask.len(method, target, hs, Http.digits.read(Http.first(lens)),
      body) : Http.Request}
  {==}

def Laws.ask_clen_takes_prefix(method, target, hs, n, body, e):
  %e : {Http.ask.short(method, target, hs, n, body, _)
    == Http.Request{method, target, hs, Http.octs.take(body, n)}
    : Http.Request}
  {==}

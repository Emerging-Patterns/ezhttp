# proofs of laws/InterimResponsesSkipped.bend
import Base
import ../src/http.bend as Http
import ../src/wirespec.bend as Spec
import ../laws/InterimResponsesSkipped.bend as Laws
import ./lemmas/DropNothing.bend as M1

def Laws.parse_splits_at_blank_line(_raw, before, after, e):
  %e : {Http.parse.cut(_) == Http.parse.head(String.lines(before), after)
    : Http.Reply}
  {==}

def Laws.reply_to(_method, _raw):
  {==}

def Laws.reply_fuel(_head, _c):
  {==}

def Laws.reply_open(_f, _head):
  {==}

def Laws.reply_interim(f, head, before, after, e):
  %e : {Http.parse.to.step(head, String.lines(before), Http.status.of(String.lines(before)), after, _,
    cut => Http.parse.to.go(f, head, cut))
    == Http.parse.to.go(f, head, Http.divide(after, "\r\n\r\n"))
    : Http.Reply}
  {==}

def Laws.reply_bare(f, head, before, after, e1, e2, n, e3):
  %e1 : {Http.parse.to.step(head, String.lines(before), Http.status.of(String.lines(before)), after, _,
    cut => Http.parse.to.go(f, head, cut))
    == Http.Reply{n, Http.head.list(String.lines(before)), ""} : Http.Reply}
  %e2 : {Http.parse.to.final(Http.status.of(String.lines(before)), String.lines(before), after, _)
    == Http.Reply{n, Http.head.list(String.lines(before)), ""} : Http.Reply}
  %e3 : {Http.parse.to.bare(_, String.lines(before))
    == Http.Reply{n, Http.head.list(String.lines(before)), ""} : Http.Reply}
  {==}

def Laws.reply_bare_none(f, head, before, after, e1, e2, e3):
  %e1 : {Http.parse.to.step(head, String.lines(before), Http.status.of(String.lines(before)), after, _,
    cut => Http.parse.to.go(f, head, cut))
    == Http.Torn{"the response has no status line"} : Http.Reply}
  %e2 : {Http.parse.to.final(Http.status.of(String.lines(before)), String.lines(before), after, _)
    == Http.Torn{"the response has no status line"} : Http.Reply}
  %e3 : {Http.parse.to.bare(_, String.lines(before))
    == Http.Torn{"the response has no status line"} : Http.Reply}
  {==}

def Laws.reply_framed(f, head, before, after, e1, e2):
  %e1 : {Http.parse.to.step(head, String.lines(before), Http.status.of(String.lines(before)), after, _,
    cut => Http.parse.to.go(f, head, cut))
    == Http.parse.head(String.lines(before), after) : Http.Reply}
  %e2 : {Http.parse.to.final(Http.status.of(String.lines(before)), String.lines(before), after, _)
    == Http.parse.head(String.lines(before), after) : Http.Reply}
  {==}

def Laws.interim_skip(_m, _after):
  {==}

def Laws.status_empty(_m):
  {==}

def Laws.heard_ok(method, text):
  dz = Equal.sym(String, String.drop(text, 0n), text, M1.eq.drop_zero(text))
  %dz : {Http.parse.to(method, _) == Http.parse.to(method, text) : Http.Reply}
  {==}

def Laws.heard_fail(method, raw, e):
  %e : {Spec.wire.heard.of(method, raw, _)
    == Http.Torn{Spec.wire.why(Spec.wire.code(raw), Spec.wire.text(raw))}
    : Http.Reply}
  {==}

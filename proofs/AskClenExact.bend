# proofs of laws/AskClenExact.bend
import Base
import ../src/http.bend as Http
import ../laws/AskClenExact.bend as Laws
import ./lemmas/NatOrder.bend as M1

def Laws.ask_clen_exact(method, target, hs, body):
  Equal.trans(Http.Request,
    Http.ask.clen(method, target, hs, Http.octs.len(body), body),
    Http.ask.short(method, target, hs, Http.octs.len(body), body, False{}),
    Http.Request{method, target, hs, body},
    Equal.cong(Bool, Http.Request,
      b => Http.ask.short(method, target, hs, Http.octs.len(body), body, b),
      Nat.is_lt(Http.octs.len(body), Http.octs.len(body)), False{},
      M1.lt_self(Http.octs.len(body))),
    Equal.cong(String, Http.Request,
      x => Http.Request{method, target, hs, x},
      Http.octs.take(body, Http.octs.len(body)), body, M1.take_all(body)))

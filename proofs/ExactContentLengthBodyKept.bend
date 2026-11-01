# proofs of laws/ExactContentLengthBodyKept.bend
import Base
import ../src/http.bend as Http
import ../laws/ExactContentLengthBodyKept.bend as Laws
import ./lemmas/NatOrder.bend as M1

def Laws.clen_exact(st, hs, body):
  Equal.trans(Http.Reply,
    Http.parse.clen(st, hs, Http.octs.len(body), body),
    Http.parse.short(st, hs, Http.octs.len(body), body, False{}),
    Http.Reply{st, hs, body},
    Equal.cong(Bool, Http.Reply,
      b => Http.parse.short(st, hs, Http.octs.len(body), body, b),
      Nat.is_lt(Http.octs.len(body), Http.octs.len(body)), False{},
      M1.lt_self(Http.octs.len(body))),
    Equal.cong(String, Http.Reply, x => Http.Reply{st, hs, x},
      Http.octs.take(body, Http.octs.len(body)), body, M1.take_all(body)))

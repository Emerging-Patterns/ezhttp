# proofs of laws/ContentLengthFramesBody.bend
import Base
import ../src/http.bend as Http
import ../laws/ContentLengthFramesBody.bend as Laws
import ../laws/OneOctetPerChar.bend as L1
import ./lemmas/OctetLength.bend as M1
import ./lemmas/OctetTakeDrop.bend as M2

def Laws.clen_short(st, hs, n, body, e):
  %e : {Http.parse.short(st, hs, n, body, _)
    == Http.Torn{"the response body stopped before its Content-Length"}
    : Http.Reply}
  {==}

# b ++ r is never shorter than b
def lt_prefix(b: String, r: String)
  -> {Nat.is_lt(String.length(String.append(b, r)), String.length(b))
    == False{} : Bool}:
  match b:
    case SNil{}:
      match r:
        case SNil{}:
          {==}
        case SCon{h, t}:
          {==}
    case SCon{h, t}:
      lt_prefix(t, r)

def Laws.clen_prefix(st, hs, b, r):
  +br = String.append(b, r)
  +n = String.length(b)
  %Equal.sym(Nat, Http.octs.len(br), String.length(br), L1.octs_len(br))
    : {Http.parse.short(st, hs, n, br, Nat.is_lt(_, n))
      == Http.Reply{st, hs, b} : Http.Reply}
  %Equal.sym(Bool, Nat.is_lt(String.length(br), n), False{}, lt_prefix(b, r))
    : {Http.parse.short(st, hs, n, br, _) == Http.Reply{st, hs, b}
      : Http.Reply}
  %Equal.sym(String, Http.octs.take(br, n), String.take(br, n),
    L1.octs_take(br, n))
    : {Http.Reply{st, hs, _} == Http.Reply{st, hs, b} : Http.Reply}
  %Equal.sym(String, String.take(br, n), b, M2.take_prefix(b, r))
    : {Http.Reply{st, hs, _} == Http.Reply{st, hs, b} : Http.Reply}
  {==}

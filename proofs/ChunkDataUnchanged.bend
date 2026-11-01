# proofs of laws/ChunkDataUnchanged.bend
import Base
import ../src/http.bend as Http
import ../laws/ChunkDataUnchanged.bend as Laws
import ../laws/OneOctetPerChar.bend as L1
import ./lemmas/DropNothing.bend as M1
import ./lemmas/OctetTakeDrop.bend as M2

# what follows |b| + k characters of b ++ r is what follows k of r
def drop_prefix(b: String, r: String, k: Nat)
  -> {String.drop(String.append(b, r), Nat.add(String.length(b), k))
    == String.drop(r, k) : String}:
  match b:
    case SNil{}:
      {==}
    case SCon{h, t}:
      drop_prefix(t, r, k)

def Laws.chunk_data(f, h, d, r, e, el):
  +a = String.append(d, "\r\n" ++ r)
  +rhs = String.append(d, Http.chunks(f, Http.divide(r, "\r\n")))
  %e : {Http.chunks.more(Http.hexlen(h), a,
    _u => Http.chunks(f, Http.divide(Http.octs.drop(a,
      Nat.add(Http.hexlen(h), 2n)), "\r\n")), _) == rhs : String}
  %el : {String.append(Http.octs.take(a, _),
    Http.chunks(f, Http.divide(Http.octs.drop(a, Nat.add(_, 2n)), "\r\n")))
    == rhs : String}
  +n = String.length(d)
  %Equal.sym(String, Http.octs.take(a, n), String.take(a, n),
    L1.octs_take(a, n))
    : {String.append(_, Http.chunks(f, Http.divide(Http.octs.drop(a,
      Nat.add(n, 2n)), "\r\n"))) == rhs : String}
  %Equal.sym(String, String.take(a, n), d, M2.take_prefix(d, "\r\n" ++ r))
    : {String.append(_, Http.chunks(f, Http.divide(Http.octs.drop(a,
      Nat.add(n, 2n)), "\r\n"))) == rhs : String}
  %Equal.sym(String, Http.octs.drop(a, Nat.add(n, 2n)),
    String.drop(a, Nat.add(n, 2n)), L1.octs_drop(a, Nat.add(n, 2n)))
    : {String.append(d, Http.chunks(f, Http.divide(_, "\r\n"))) == rhs
      : String}
  %Equal.sym(String, String.drop(a, Nat.add(n, 2n)), r,
    Equal.trans(String, String.drop(a, Nat.add(n, 2n)), String.drop(r, 0n), r,
      drop_prefix(d, "\r\n" ++ r, 2n), M1.eq.drop_zero(r)))
    : {String.append(d, Http.chunks(f, Http.divide(_, "\r\n"))) == rhs
      : String}
  {==}

def Laws.chunk_last(_f, h, after, e):
  %e : {Http.chunks.more(Http.hexlen(h), after,
    _u => Http.chunks(_f, Http.divide(Http.octs.drop(after,
      Nat.add(Http.hexlen(h), 2n)), "\r\n")), _) == "" : String}
  {==}

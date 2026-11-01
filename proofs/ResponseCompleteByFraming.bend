# proofs of laws/ResponseCompleteByFraming.bend
import Base
import ../src/http.bend as Http
import ../laws/ResponseCompleteByFraming.bend as Laws
import ./lemmas/BaseEqualities.bend as M1

def Laws.whole_open(_f, _asked):
  {==}

def Laws.whole_head(f, asked, before, after, e):
  %e : {Http.whole.step(asked, String.lines(before), after, _,
    cut => Http.whole.go(f, asked, cut))
    == Http.whole.of(Http.frame(Bool.or(asked, Http.status.bare(Http.status.of(String.lines(before)))),
      Http.head.go(String.lines(before), "transfer-encoding"),
      Http.head.values(String.lines(before), "content-length")), after) : Bool}
  {==}

def Laws.status_of(_ls):
  {==}

def Laws.status_bare_some(_n):
  {==}

def Laws.status_bare_none(_m, e):
  %e : {Http.status.bare(_) == False{} : Bool}
  {==}

def Laws.frame_bare(_te, _lens):
  {==}

def Laws.frame_chunked(_te, lens, e):
  %e : {Http.frame.te(lens, _) == Http.Chunked{} : Http.Frame}
  {==}

def Laws.frame_sized(_te, lens, e1, e2, n, e3):
  %e1 : {Http.frame.te(lens, _) == Http.Sized{n} : Http.Frame}
  %e2 : {Http.frame.agree(lens, _) == Http.Sized{n} : Http.Frame}
  %e3 : {Http.frame.sized(_) == Http.Sized{n} : Http.Frame}
  {==}

def Laws.frame_disagree(_te, lens, e1, e2):
  %e1 : {Http.frame.te(lens, _) == Http.Closed{} : Http.Frame}
  %e2 : {Http.frame.agree(lens, _) == Http.Closed{} : Http.Frame}
  {==}

def Laws.frame_unsized(_te, lens, e1, e2, e3):
  %e1 : {Http.frame.te(lens, _) == Http.Closed{} : Http.Frame}
  %e2 : {Http.frame.agree(lens, _) == Http.Closed{} : Http.Frame}
  %e3 : {Http.frame.sized(_) == Http.Closed{} : Http.Frame}
  {==}

# --- counting octets without walking all of them (utf8.has) ---

law lt_over:
  for k: Nat
  for w: Nat
  for +l: Nat
  for e: {True{} == Nat.is_lt(k, w) : Bool}
  {Nat.is_lt(Nat.add(w, l), k) == False{} : Bool}

def lt_over(k, w, l, e):
  match k w:
    case 0n 0n:
      M1.eq.bit.absurd(&2, {Nat.is_lt(Nat.add(0n, l), 0n) == False{} : Bool},
        Equal.sym(Bool, True{}, False{}, e))
    case 0n 1n+p:
      {==}
    case 1n+q 0n:
      M1.eq.bit.absurd(&2, {Nat.is_lt(Nat.add(0n, l), 1n+q) == False{} : Bool},
        Equal.sym(Bool, True{}, False{}, e))
    case 1n+q 1n+p:
      lt_over(q, p, l, e)

law lt_shift:
  for k: Nat
  for w: Nat
  for +l: Nat
  for e: {False{} == Nat.is_lt(k, w) : Bool}
  {Nat.is_lt(Nat.add(w, l), k) == Nat.is_lt(l, Nat.sub(k, w)) : Bool}

def lt_shift(k, w, l, e):
  match k w:
    case 0n 0n:
      {==}
    case 1n+q 0n:
      {==}
    case 0n 1n+p:
      M1.eq.bit.absurd(&2, {Nat.is_lt(Nat.add(1n+p, l), 0n)
        == Nat.is_lt(l, Nat.sub(0n, 1n+p)) : Bool}, e)
    case 1n+q 1n+p:
      lt_shift(q, p, l, e)

law has_len.arm:
  for n: Nat
  for w: Nat
  for +l: Nat
  for r: Bool
  for b: Bool
  for e: {b == Nat.is_lt(n, w) : Bool}
  for ih: {r == Bool.not(Nat.is_lt(l, Nat.sub(n, w))) : Bool}
  {Http.octs.has.step(b, _u => r) == Bool.not(Nat.is_lt(Nat.add(w, l), n))
    : Bool}

def has_len.arm(n, w, l, r, b, e, ih):
  match b:
    case True{}:
      Equal.cong(Bool, Bool, x => Bool.not(x), False{},
        Nat.is_lt(Nat.add(w, l), n),
        Equal.sym(Bool, Nat.is_lt(Nat.add(w, l), n), False{},
          lt_over(n, w, l, e)))
    case False{}:
      Equal.trans(Bool, r, Bool.not(Nat.is_lt(l, Nat.sub(n, w))),
        Bool.not(Nat.is_lt(Nat.add(w, l), n)), ih,
        Equal.cong(Bool, Bool, x => Bool.not(x),
          Nat.is_lt(l, Nat.sub(n, w)), Nat.is_lt(Nat.add(w, l), n),
          Equal.sym(Bool, Nat.is_lt(Nat.add(w, l), n),
            Nat.is_lt(l, Nat.sub(n, w)), lt_shift(n, w, l, e))))

law has_len:
  for s: String
  for +n: Nat
  {Http.octs.has(s, n) == Bool.not(Nat.is_lt(Http.octs.len(s), n)) : Bool}

def has_len(s, n):
  match s:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      +w = Http.octs.width(Char.to_u32(h))
      has_len.arm(n, w, Http.octs.len(t), Http.octs.has(t, Nat.sub(n, w)),
        Nat.is_lt(n, w), {==}, has_len(t, Nat.sub(n, w)))

def Laws.whole_bare(_body):
  {==}

def Laws.whole_sized(_n, _body):
  {==}

def Laws.whole_chunked(_body):
  {==}

def Laws.whole_closed(_body):
  {==}

def Laws.ended_fuel(_c):
  {==}

def Laws.ended_open(_f):
  {==}

def Laws.ended_bad(f, before, after, e):
  %e : {Http.chunks.ended.hex(before, after, _,
    cut => Http.chunks.ended(f, cut)) == True{} : Bool}
  {==}

def Laws.ended_last(f, before, after, e1, e2):
  %e1 : {Http.chunks.ended.hex(before, after, _,
    cut => Http.chunks.ended(f, cut)) == Http.chunks.trailer(after) : Bool}
  %e2 : {Http.chunks.ended.size(after, Http.hexlen(before), _,
    cut => Http.chunks.ended(f, cut)) == Http.chunks.trailer(after) : Bool}
  {==}

def Laws.ended_next(f, before, after, e1, e2, e3):
  %e1 : {Http.chunks.ended.hex(before, after, _,
    cut => Http.chunks.ended(f, cut)) == Http.chunks.ended(f, Http.divide(Http.octs.drop(after,
      Nat.add(Http.hexlen(before), 2n)), "\r\n")) : Bool}
  %e2 : {Http.chunks.ended.size(after, Http.hexlen(before), _,
    cut => Http.chunks.ended(f, cut)) == Http.chunks.ended(f, Http.divide(Http.octs.drop(after,
      Nat.add(Http.hexlen(before), 2n)), "\r\n")) : Bool}
  %e3 : {Http.chunks.ended.data(after, Http.hexlen(before), _,
    cut => Http.chunks.ended(f, cut)) == Http.chunks.ended(f, Http.divide(Http.octs.drop(after,
      Nat.add(Http.hexlen(before), 2n)), "\r\n")) : Bool}
  {==}

def Laws.ended_short(f, before, after, e1, e2, e3):
  %e1 : {Http.chunks.ended.hex(before, after, _,
    cut => Http.chunks.ended(f, cut)) == False{} : Bool}
  %e2 : {Http.chunks.ended.size(after, Http.hexlen(before), _,
    cut => Http.chunks.ended(f, cut)) == False{} : Bool}
  %e3 : {Http.chunks.ended.data(after, Http.hexlen(before), _,
    cut => Http.chunks.ended(f, cut)) == False{} : Bool}
  {==}

def Laws.trailer_ended(_after):
  {==}

def Laws.chunk_ready(after, n):
  Equal.cong(Bool, Bool,
    x => Bool.and(x, String.starts_with(Http.octs.drop(after, n), "\r\n")),
    Http.octs.has(after, Nat.add(n, 2n)),
    Bool.not(Nat.is_lt(Http.octs.len(after), Nat.add(n, 2n))),
    has_len(after, Nat.add(n, 2n)))

def Laws.whole_go(_method, _raw):
  {==}

def Laws.whole_fuel(_asked, _c):
  {==}

def Laws.whole_interim(f, asked, before, after, e):
  %e : {Http.whole.step(asked, String.lines(before), after, _,
    cut => Http.whole.go(f, asked, cut))
    == Http.whole.go(f, asked, Http.divide(after, "\r\n\r\n")) : Bool}
  {==}

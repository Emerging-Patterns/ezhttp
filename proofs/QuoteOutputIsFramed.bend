# proofs of laws/QuoteOutputIsFramed.bend
import Base
import ../src/pct.bend as Pct
import ../laws/QuoteOutputIsFramed.bend as Laws
import ../laws/defs/PercentFrame.bend as D1
import ./lemmas/BaseEqualities.bend as M1

def Laws.frame_kept(slash, c, e, rest):
  %e : {D1.framed(slash, Pct.one.of(c, rest, _), 0n)
    == D1.framed(slash, rest, 0n) : Bool}
  %e : {Bool.and(Bool.or(_, U32.is_eq(c, 37)),
    D1.framed(slash, rest,
      Bool.pick(Nat, _, 0n, Bool.pick(Nat, U32.is_eq(c, 37), 2n, 0n))))
    == D1.framed(slash, rest, 0n) : Bool}
  {==}

# LAW: one %XX triple whose nibbles are hex digits stays in the frame
law frame_bytes.step:
  for +slash: Bool
  for +b: U32
  for t: List<&2, U32>
  for +rest: String
  for e1: {True{} == D1.hexdig(Pct.hex(U32.shrn(b, 4n))) : Bool}
  for e2: {True{} == D1.hexdig(Pct.hex(U32.and(b, 15))) : Bool}
  for ih: {D1.framed(slash, Pct.pct(t, rest), 0n)
    == D1.framed(slash, rest, 0n) : Bool}
  {D1.framed(slash, Pct.pct(b <> t, rest), 0n)
    == D1.framed(slash, rest, 0n) : Bool}

def frame_bytes.step(slash, b, t, rest, e1, e2, ih):
  %e1 : {Bool.and(_, Bool.and(D1.hexdig(Pct.hex(U32.and(b, 15))),
    D1.framed(slash, Pct.pct(t, rest), 0n)))
    == D1.framed(slash, rest, 0n) : Bool}
  %e2 : {Bool.and(_, D1.framed(slash, Pct.pct(t, rest), 0n))
    == D1.framed(slash, rest, 0n) : Bool}
  ih

def Laws.frame_bytes(slash, bs, e, rest):
  match bs:
    case []:
      {==}
    case +b <> +t:
      frame_bytes.step(slash, b, t, rest,
        Equal.sym(Bool, D1.hexdig(Pct.hex(U32.shrn(b, 4n))), True{},
          M1.eq.and.left(D1.hexdig(Pct.hex(U32.shrn(b, 4n))),
            Bool.and(D1.hexdig(Pct.hex(U32.and(b, 15))), Laws.hexes(t)), e)),
        Equal.sym(Bool, D1.hexdig(Pct.hex(U32.and(b, 15))), True{},
          M1.eq.and.left(D1.hexdig(Pct.hex(U32.and(b, 15))), Laws.hexes(t),
            M1.eq.and.right(D1.hexdig(Pct.hex(U32.shrn(b, 4n))),
              Bool.and(D1.hexdig(Pct.hex(U32.and(b, 15))), Laws.hexes(t)),
              e))),
        Laws.frame_bytes(slash, t,
          M1.eq.and.right(D1.hexdig(Pct.hex(U32.and(b, 15))), Laws.hexes(t),
            M1.eq.and.right(D1.hexdig(Pct.hex(U32.shrn(b, 4n))),
              Bool.and(D1.hexdig(Pct.hex(U32.and(b, 15))), Laws.hexes(t)),
              e)),
          rest))

# LAW: one character stays in the frame, kept or escaped
law frame_char:
  for +slash: Bool
  for +c: U32
  for +k: Bool
  for +ek: {k == Pct.safe(slash, c) : Bool}
  for +h: {Bool.or(k, Laws.hexes(Pct.utf8(c))) == True{} : Bool}
  for +rest: String
  {D1.framed(slash, Pct.one(slash, c, rest), 0n)
    == D1.framed(slash, rest, 0n) : Bool}

def frame_char(slash, c, k, ek, h, rest):
  match k:
    case True{}:
      Laws.frame_kept(slash, c, ek, rest)
    case False{}:
      %ek : {D1.framed(slash, Pct.one.of(c, rest, _), 0n)
        == D1.framed(slash, rest, 0n) : Bool}
      Laws.frame_bytes(slash, Pct.utf8(c), h, rest)

def Laws.frame_quote(slash, str, e):
  match str:
    case SNil{}:
      {==}
    case SCon{Chr{+c}, +t}:
      Equal.trans(Bool,
        D1.framed(slash, Pct.one(slash, c, Pct.quote(slash, t)), 0n),
        D1.framed(slash, Pct.quote(slash, t), 0n),
        True{},
        frame_char(slash, c, Pct.safe(slash, c), {==},
          M1.eq.and.left(Bool.or(Pct.safe(slash, c), Laws.hexes(Pct.utf8(c))),
            Laws.nibbles(slash, t), e),
          Pct.quote(slash, t)),
        Laws.frame_quote(slash, t,
          M1.eq.and.right(Bool.or(Pct.safe(slash, c), Laws.hexes(Pct.utf8(c))),
            Laws.nibbles(slash, t), e)))

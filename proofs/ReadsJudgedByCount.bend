# proofs of laws/ReadsJudgedByCount.bend
import Base
import ../src/http.bend as Http
import ../src/wirespec.bend as Spec
import ../laws/OneOctetPerChar.bend as L1
import ../laws/ReadStateMatchesWholeText.bend as L2
import ../laws/ReadsJudgedByCount.bend as Laws
import ./lemmas/BaseEqualities.bend as M1
import ./lemmas/NatOrder.bend as M2
import ./lemmas/OctetLength.bend as M3
import ./lemmas/WalksOverAppendedText.bend as M4

# --- reading packed octets, read by read ---

def Laws.read_closed(_h):
  {==}

def Laws.skip_short(b, n, e):
  match b:
    case SNil{}:
      Equal.cong(Nat, Http.Skip, x => Http.Short{x}, n, Nat.sub(n, 0n),
        Equal.sym(Nat, Nat.sub(n, 0n), n, M2.sub_zero(n)))
    case SCon{+h, +t}:
      match n:
        case 0n:
          M1.eq.bit.absurd(&2, {Http.octs.skip(SCon{h, t}, 0n)
            == Http.Short{Nat.sub(0n, String.length(SCon{h, t}))} : Http.Skip}, e)
        case 1n+k:
          match k:
            case 0n:
              Laws.skip_short(t, 0n, e)
            case 1n+j:
              Laws.skip_short(t, 1n+j, e)

def Laws.hear_count(h, b, e):
  match h:
    case Http.Heads{fuel, asked, raw}:
      M1.eq.bit.absurd(&2, {Http.hear.more.n(Http.Heads{fuel, asked, raw}, String.length(b))
        == Http.hear.more(Http.Heads{fuel, asked, raw}, b) : Http.Hear},
        Equal.sym(Bool, True{}, False{}, e))
    case Http.Whole{}:
      {==}
    case Http.Never{}:
      {==}
    case Http.Count{n, have}:
      Equal.cong(Nat, Http.Hear, x => Http.Count{n, Nat.add(have, x)},
        String.length(b), Http.octs.len(b),
        Equal.sym(Nat, Http.octs.len(b), String.length(b), L1.octs_len(b)))
    case Http.Walking{w}:
      match w:
        case Http.Ended{}:
          M1.eq.bit.absurd(&2, {Http.hear.more.n(Http.Walking{Http.Ended{}}, String.length(b))
            == Http.hear.more(Http.Walking{Http.Ended{}}, b) : Http.Hear},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.Hold{fuel, rest}:
          M1.eq.bit.absurd(&2, {Http.hear.more.n(Http.Walking{Http.Hold{fuel, rest}}, String.length(b))
            == Http.hear.more(Http.Walking{Http.Hold{fuel, rest}}, b) : Http.Hear},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.Tail{fuel, left, rest}:
          M1.eq.bit.absurd(&2, {Http.hear.more.n(Http.Walking{Http.Tail{fuel, left, rest}}, String.length(b))
            == Http.hear.more(Http.Walking{Http.Tail{fuel, left, rest}}, b) : Http.Hear},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.Owed{+g, +owed}:
          +f = Nat.add(g, String.length(b))
          +lt = Equal.sym(Bool, Nat.is_lt(owed, String.length(b)), False{},
            M1.eq.not.true(Nat.is_lt(owed, String.length(b)), Equal.sym(Bool, True{},
              Bool.not(Nat.is_lt(owed, String.length(b))), e)))
          Equal.cong(Http.Skip, Http.Hear,
            x => Http.Walking{Http.walk.data(f, x, s => Http.walk(f, s))},
            Http.Short{Nat.sub(owed, String.length(b))}, Http.octs.skip(b, owed),
            Equal.sym(Http.Skip, Http.octs.skip(b, owed), Http.Short{Nat.sub(owed, String.length(b))},
              Laws.skip_short(b, owed, lt)))

def Laws.read_count(h, b, e1, e2):
  match b:
    case SNil{}:
      M1.eq.bit.absurd(&2, {Spec.wire.read.count(h, 0n)
        == Some{Spec.wire.read.next(h, "")} : Maybe<&2, Spec.Read>}, e1)
    case SCon{+c, +t}:
      +L = String.length(SCon{c, t})
      +e = e2
      %e : {Spec.wire.read.counted(h, L, _)
        == Some{Spec.wire.read.next(h, SCon{c, t})} : Maybe<&2, Spec.Read>}
      Equal.cong(Http.Hear, Maybe<&2, Spec.Read>, x => Some{Spec.wire.read.with(x)},
        Http.hear.more.n(h, L), Http.hear.more(h, SCon{c, t}),
        Laws.hear_count(h, SCon{c, t}, e))

def Laws.read_whole(method, a, text, e1, e2):
  +H0 = Http.hear.of(method, a)
  +J = a ++ text
  %e1 : {Spec.wire.read.got(H0, text, _) == Spec.Heard{} : Spec.Read}
  %Equal.sym(Http.Hear, Http.hear.more(H0, text), Http.hear.of(method, J),
    L2.hear_more(method, a, text))
    : {Spec.wire.read.done(_, Http.hear.done(_)) == Spec.Heard{} : Spec.Read}
  %Equal.sym(Bool, Http.hear.done(Http.hear.of(method, J)), Http.whole(method, J),
    L2.hear_done(method, J))
    : {Spec.wire.read.done(Http.hear.of(method, J), _) == Spec.Heard{} : Spec.Read}
  %e2 : {Spec.wire.read.done(Http.hear.of(method, J), _) == Spec.Heard{} : Spec.Read}
  {==}

def Laws.read_more(method, a, text, e1, e2):
  +H0 = Http.hear.of(method, a)
  +J = a ++ text
  %e1 : {Spec.wire.read.got(H0, text, _) == Spec.Again{Http.hear.of(method, J)}
    : Spec.Read}
  %Equal.sym(Http.Hear, Http.hear.more(H0, text), Http.hear.of(method, J),
    L2.hear_more(method, a, text))
    : {Spec.wire.read.done(_, Http.hear.done(_))
      == Spec.Again{Http.hear.of(method, J)} : Spec.Read}
  %Equal.sym(Bool, Http.hear.done(Http.hear.of(method, J)), Http.whole(method, J),
    L2.hear_done(method, J))
    : {Spec.wire.read.done(Http.hear.of(method, J), _)
      == Spec.Again{Http.hear.of(method, J)} : Spec.Read}
  %e2 : {Spec.wire.read.done(Http.hear.of(method, J), _)
    == Spec.Again{Http.hear.of(method, J)} : Spec.Read}
  {==}

# the frame of percent-encoded text: kept characters and `%HH` triples
import Base
import ../../src/pct.bend as Pct

# an upper-case hex digit: 0-9 or A-F
def hexdig(ch: Char) -> Bool:
  match ch:
    case Chr{+code}:
      Bool.or(Bool.and(U32.is_le(48, code), U32.is_le(code, 57)),
        Bool.and(U32.is_le(65, code), U32.is_le(code, 70)))

# whether character cp may come next, `need` hex digits still owed to a "%":
# with none owed, a kept character or a "%"; otherwise a hex digit
def framed.ok(slash: Bool, +cp: U32, need: Nat) -> Bool:
  match need:
    case 0n:
      Bool.or(Pct.safe(slash, cp), U32.is_eq(cp, 37))
    case 1n+p:
      hexdig(Chr{cp})

# hex digits owed after character cp: two after a "%", one fewer after a digit
def framed.next(slash: Bool, +cp: U32, need: Nat) -> Nat:
  match need:
    case 0n:
      Bool.pick(Nat, Pct.safe(slash, cp), 0n,
        Bool.pick(Nat, U32.is_eq(cp, 37), 2n, 0n))
    case 1n+p:
      p

# no hex digit is still owed at the end
def framed.end(need: Nat) -> Bool:
  match need:
    case 0n:
      True{}
    case 1n+p:
      False{}

# the laws/QuoteOutputIsFramed.bend frame read left to right: kept
# characters, and "%" followed by exactly two hex digits
def framed(+slash: Bool, str: String, +need: Nat) -> Bool:
  match str:
    case SNil{}:
      framed.end(need)
    case SCon{Chr{+cp}, tail}:
      Bool.and(framed.ok(slash, cp, need),
        framed(slash, tail, framed.next(slash, cp, need)))

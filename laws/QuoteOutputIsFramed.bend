# For every string, the output holds only unreserved characters, `/` (path
# form only) and `%HH` triples whose `H` are `0`-`9` or `A`-`F`.
#
# pending: the laws here prove part of this, not all of it.
#
# proved so far: `frame_quote`: the whole output of either form is in the
# frame (kept characters, and `%` followed by exactly two upper-case hex
# digits, read left to right with nothing owed at the end), given `nibbles`:
# every character the form does not keep has UTF-8 bytes whose high and low
# nibbles `hex` writes as `0`-`9` or `A`-`F`. `frame_kept` and `frame_bytes`
# are its steps. Left to prove: `nibbles` for every string of Unicode scalar
# values: each byte `utf8` yields for a code point up to U+10FFFF is below
# 256, so both nibbles are below 16, and `hex` of a value below 16 is a hex
# digit. This is bit arithmetic on `U32` (shifts, masks, comparisons on
# symbolic words) that Base has no lemmas for yet.
import Base
import ../src/pct.bend as Pct
import ./defs/PercentFrame.bend as D1

# both nibbles of every byte are written as hex digits
def hexes(bs: List<&2, U32>) -> Bool:
  match bs:
    case []:
      True{}
    case +byte <> tail:
      Bool.and(D1.hexdig(Pct.hex(U32.shrn(byte, 4n))),
        Bool.and(D1.hexdig(Pct.hex(U32.and(byte, 15))), hexes(tail)))

# LAW (partial): a kept character stays in the frame
law frame_kept:
  for +slash: Bool
  for +c: U32
  for +e: {True{} == Pct.safe(slash, c) : Bool}
  for rest: String
  {D1.framed(slash, Pct.one(slash, c, rest), 0n) == D1.framed(slash, rest, 0n)
    : Bool}

# LAW (partial): %XX triples stay in the frame when their nibbles are hex
# digits
law frame_bytes:
  for +slash: Bool
  for bs: List<&2, U32>
  for +e: {hexes(bs) == True{} : Bool}
  for +rest: String
  {D1.framed(slash, Pct.pct(bs, rest), 0n) == D1.framed(slash, rest, 0n) : Bool}

# every character the form does not keep has UTF-8 bytes whose nibbles are
# written as hex digits
def nibbles(+slash: Bool, str: String) -> Bool:
  match str:
    case SNil{}:
      True{}
    case SCon{Chr{+cp}, tail}:
      Bool.and(Bool.or(Pct.safe(slash, cp), hexes(Pct.utf8(cp))),
        nibbles(slash, tail))

# LAW (partial): the whole output is in the frame, given that every escaped
# character's nibbles are written as hex digits
law frame_quote:
  for +slash: Bool
  for +str: String
  for +e: {nibbles(slash, str) == True{} : Bool}
  {D1.framed(slash, Pct.quote(slash, str), 0n) == True{} : Bool}

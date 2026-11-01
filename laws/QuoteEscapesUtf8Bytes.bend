# Every character a form does not keep is written as `%XX` for each byte of
# its UTF-8 encoding, in order (RFC 3986 §2.1, RFC 3629 §3), `XX` being the
# byte's high then low nibble as hex digits `0`-`9` and upper-case `A`-`F`.
import Base
import ../src/pct.bend as Pct

# LAW (RFC 3986 §2.1): a character the form does not keep is written as the
# %XX triples of its UTF-8 bytes
law one_escaped:
  for slash: Bool
  for +c: U32
  for e: {False{} == Pct.safe(slash, c) : Bool}
  for rest: String
  {Pct.one(slash, c, rest) == Pct.pct(Pct.utf8(c), rest) : String}

# LAW: no bytes write nothing
law pct_nil:
  for rest: String
  {Pct.pct([], rest) == rest : String}

# LAW (RFC 3986 §2.1): a byte is written as "%", its high nibble, its low
# nibble, before the bytes after it
law pct_cons:
  for +b: U32
  for bs: List<&2, U32>
  for rest: String
  {Pct.pct(b <> bs, rest)
    == SCon{'%', SCon{Pct.hex(U32.shrn(b, 4n)),
      SCon{Pct.hex(U32.and(b, 15)), Pct.pct(bs, rest)}}} : String}

# LAW: a nibble below 10 is the digit '0' + n
law hex_digit:
  for +n: U32
  for e: {True{} == U32.is_lt(n, 10) : Bool}
  {Pct.hex(n) == Chr{U32.add(48, n)} : Char}

# LAW (RFC 3986 §2.1, upper case): a nibble of 10 or more is the letter
# 'A' + (n - 10), that is code 55 + n
law hex_letter:
  for +n: U32
  for e: {False{} == U32.is_lt(n, 10) : Bool}
  {Pct.hex(n) == Chr{U32.add(55, n)} : Char}

# LAW (RFC 3629 §3): U+0000 to U+007F is one byte, 0xxxxxxx
law utf8_one:
  for +c: U32
  for e: {True{} == U32.is_lt(c, 128) : Bool}
  {Pct.utf8(c) == [c] : List<&2, U32>}

# LAW (RFC 3629 §3): U+0080 to U+07FF is two bytes, 110xxxxx 10xxxxxx
law utf8_two:
  for +c: U32
  for e1: {False{} == U32.is_lt(c, 128) : Bool}
  for e2: {True{} == U32.is_lt(c, 2048) : Bool}
  {Pct.utf8(c) == [U32.or(192, U32.shrn(c, 6n)),
    U32.or(128, U32.and(c, 63))] : List<&2, U32>}

# LAW (RFC 3629 §3): U+0800 to U+FFFF is three bytes,
# 1110xxxx 10xxxxxx 10xxxxxx
law utf8_three:
  for +c: U32
  for e1: {False{} == U32.is_lt(c, 128) : Bool}
  for e2: {False{} == U32.is_lt(c, 2048) : Bool}
  for e3: {True{} == U32.is_lt(c, 65536) : Bool}
  {Pct.utf8(c) == [U32.or(224, U32.shrn(c, 12n)),
    U32.or(128, U32.and(U32.shrn(c, 6n), 63)),
    U32.or(128, U32.and(c, 63))] : List<&2, U32>}

# LAW (RFC 3629 §3): U+10000 to U+10FFFF is four bytes,
# 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
law utf8_four:
  for +c: U32
  for e1: {False{} == U32.is_lt(c, 128) : Bool}
  for e2: {False{} == U32.is_lt(c, 2048) : Bool}
  for e3: {False{} == U32.is_lt(c, 65536) : Bool}
  {Pct.utf8(c) == [U32.or(240, U32.shrn(c, 18n)),
    U32.or(128, U32.and(U32.shrn(c, 12n), 63)),
    U32.or(128, U32.and(U32.shrn(c, 6n), 63)),
    U32.or(128, U32.and(c, 63))] : List<&2, U32>}

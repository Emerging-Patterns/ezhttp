# `unquote(s)` and `unquote_plus(s)` (`src/qs.bend`) percent-decode a string
# as RFC 3986 §2.1 describes ("a percent-encoded octet is encoded as a
# character triplet, consisting of the percent character "%" followed by the
# two hexadecimal digits representing that octet's numeric value"; upper-
# and lower-case hex digits are equivalent), the way Python's
# `urllib.parse.unquote(s)` and `urllib.parse.unquote_plus(s)` do; the bytes
# are read as UTF-8 (RFC 3629 §4) with `errors="replace"`. `quote_plus`,
# `urlencode`, `parse_query` and `query_get` read and write
# `application/x-www-form-urlencoded` query strings (WHATWG URL §5) the way
# `urllib.parse.quote_plus`, `urlencode(pairs)` and `parse_qsl(text,
# keep_blank_values=True)` do. A pair is `(name, value)`, a reusable `String
# & String` (`Kv()`).
#
# For every string, `unquote` reads it left to right into bytes and
# characters (`Qs.toks`) and decodes those as UTF-8
# (laws/Utf8DecodesWithReplacement.bend). A character outside ASCII is kept
# as itself and ends the run of bytes before it, so each maximal ASCII run
# is decoded on its own, as Python decodes it. In a run, `%` followed by two
# hex digits (`0`-`9`, `A`-`F`, `a`-`f`, RFC 3986 §2.1) is the byte they
# name, high digit first; a `%` not followed by two hex digits is the byte
# `%` (and a single hex digit after it its own byte), the escape left as
# written; every other ASCII character is its own byte.
import Base
import ../src/http.bend as Http
import ../src/qs.bend as Qs

# --- percent-decoding and query strings ---

# LAW: unquote reads a string into bytes and characters from plain text, then
# decodes them as UTF-8 from between characters
law qs_unquote:
  for s: String
  {Qs.unquote(s) == Qs.utf.dec(Qs.toks(s, False{}, Qs.Plain{}), Qs.Idle{})
    : String}

# LAW: at the end of the text, what is left open is written as it stands
law qs_toks_nil:
  for plus: Bool
  for st: Qs.Esc
  {Qs.toks("", plus, st) == Qs.tok.end(st) : List<&2, Qs.Tok>}

# LAW: the text is read one character at a time, from where the reading stands
law qs_toks_cons:
  for +c: Char
  for t: String
  for +plus: Bool
  for st: Qs.Esc
  {Qs.toks(SCon{c, t}, plus, st)
    == Qs.tok.step(plus, st, c, st2 => Qs.toks(t, plus, st2))
    : List<&2, Qs.Tok>}

# LAW: in plain text, a character outside ASCII is kept as itself
law qs_tok_wide:
  for plus: Bool
  for +c: Char
  for k: Qs.Esc -> List<&2, Qs.Tok>
  for e: {True{} == U32.is_ge(Char.to_u32(c), 128) : Bool}
  {Qs.tok.step(plus, Qs.Plain{}, c, k) == Qs.W{c} <> k(Qs.Plain{})
    : List<&2, Qs.Tok>}

# LAW (RFC 3986 §2.1): in plain text, `%` opens an escape
law qs_tok_open:
  for plus: Bool
  for +c: Char
  for k: Qs.Esc -> List<&2, Qs.Tok>
  for e1: {False{} == U32.is_ge(Char.to_u32(c), 128) : Bool}
  for e2: {True{} == Char.is_eq(c, '%') : Bool}
  {Qs.tok.step(plus, Qs.Plain{}, c, k) == k(Qs.Pct{}) : List<&2, Qs.Tok>}

# LAW: in plain text, every other ASCII character is a byte
law qs_tok_byte:
  for plus: Bool
  for +c: Char
  for k: Qs.Esc -> List<&2, Qs.Tok>
  for e1: {False{} == U32.is_ge(Char.to_u32(c), 128) : Bool}
  for e2: {False{} == Char.is_eq(c, '%') : Bool}
  {Qs.tok.step(plus, Qs.Plain{}, c, k)
    == Qs.B{Qs.tok.byte(plus, c)} <> k(Qs.Plain{}) : List<&2, Qs.Tok>}

# LAW: any other plain character is the byte of its own code
law qs_byte_other:
  for plus: Bool
  for +c: Char
  for e: {False{} == Bool.and(plus, Char.is_eq(c, '+')) : Bool}
  {Qs.tok.byte(plus, c) == Char.to_u32(c) : U32}

# LAW (RFC 3986 §2.1): after `%`, a hex digit is held for the next one
law qs_tok_pct_hex:
  for plus: Bool
  for +c: Char
  for k: Qs.Esc -> List<&2, Qs.Tok>
  for e: {True{} == Qs.tok.hex(c) : Bool}
  {Qs.tok.step(plus, Qs.Pct{}, c, k) == k(Qs.Pct1{c}) : List<&2, Qs.Tok>}

# LAW: after `%`, any other character leaves the `%` as written and is read
# in plain text
law qs_tok_pct_other:
  for +plus: Bool
  for +c: Char
  for k: Qs.Esc -> List<&2, Qs.Tok>
  for e: {False{} == Qs.tok.hex(c) : Bool}
  {Qs.tok.step(plus, Qs.Pct{}, c, k)
    == Qs.B{37} <> Qs.tok.step(plus, Qs.Plain{}, c, k) : List<&2, Qs.Tok>}

# LAW (RFC 3986 §2.1): `%` and two hex digits are the byte they name, the
# first digit high
law qs_tok_pct1_hex:
  for plus: Bool
  for +d: Char
  for +c: Char
  for k: Qs.Esc -> List<&2, Qs.Tok>
  for e: {True{} == Qs.tok.hex(c) : Bool}
  {Qs.tok.step(plus, Qs.Pct1{d}, c, k)
    == Qs.B{U32.add(U32.mul(Http.hex.val(d), 16), Http.hex.val(c))}
      <> k(Qs.Plain{}) : List<&2, Qs.Tok>}

# LAW: `%` and one hex digit before anything else are written as they stand
# and the character is read in plain text
law qs_tok_pct1_other:
  for +plus: Bool
  for +d: Char
  for +c: Char
  for k: Qs.Esc -> List<&2, Qs.Tok>
  for e: {False{} == Qs.tok.hex(c) : Bool}
  {Qs.tok.step(plus, Qs.Pct1{d}, c, k)
    == Qs.B{37} <> (Qs.B{Char.to_u32(d)}
      <> Qs.tok.step(plus, Qs.Plain{}, c, k)) : List<&2, Qs.Tok>}

# LAW: plain text ends with nothing left open
law qs_tok_end_plain:
  for st: Qs.Esc
  for e: {Qs.Plain{} == st : Qs.Esc}
  {Qs.tok.end(st) == [] : List<&2, Qs.Tok>}

# LAW: a `%` at the end is written as it stands
law qs_tok_end_pct:
  for st: Qs.Esc
  for e: {Qs.Pct{} == st : Qs.Esc}
  {Qs.tok.end(st) == [Qs.B{37}] : List<&2, Qs.Tok>}

# LAW: a `%` and one hex digit at the end are written as they stand
law qs_tok_end_pct1:
  for +d: Char
  {Qs.tok.end(Qs.Pct1{d}) == [Qs.B{37}, Qs.B{Char.to_u32(d)}]
    : List<&2, Qs.Tok>}

# LAW: a hex digit is a character whose hex value is below 16
law qs_tok_hex:
  for c: Char
  {Qs.tok.hex(c) == U32.is_lt(Http.hex.val(c), 16) : Bool}

# LAW: `0`-`9` are worth 0 to 9
law qs_hexval_dec:
  for +u: U32
  for e: {True{} == Bool.and(U32.is_ge(u, 48), U32.is_le(u, 57)) : Bool}
  {Http.hex.val(Chr{u}) == U32.sub(u, 48) : U32}

# LAW: `A`-`F` are worth 10 to 15
law qs_hexval_upper:
  for +u: U32
  for e1: {False{} == Bool.and(U32.is_ge(u, 48), U32.is_le(u, 57)) : Bool}
  for e2: {False{} == Bool.and(U32.is_ge(u, 97), U32.is_le(u, 102)) : Bool}
  for e3: {True{} == Bool.and(U32.is_ge(u, 65), U32.is_le(u, 70)) : Bool}
  {Http.hex.val(Chr{u}) == U32.sub(u, 55) : U32}

# LAW: `a`-`f` are worth 10 to 15
law qs_hexval_lower:
  for +u: U32
  for e1: {False{} == Bool.and(U32.is_ge(u, 48), U32.is_le(u, 57)) : Bool}
  for e2: {True{} == Bool.and(U32.is_ge(u, 97), U32.is_le(u, 102)) : Bool}
  {Http.hex.val(Chr{u}) == U32.sub(u, 87) : U32}

# LAW: every other character is no hex digit (16)
law qs_hexval_none:
  for +u: U32
  for e1: {False{} == Bool.and(U32.is_ge(u, 48), U32.is_le(u, 57)) : Bool}
  for e2: {False{} == Bool.and(U32.is_ge(u, 97), U32.is_le(u, 102)) : Bool}
  for e3: {False{} == Bool.and(U32.is_ge(u, 65), U32.is_le(u, 70)) : Bool}
  {Http.hex.val(Chr{u}) == 16 : U32}

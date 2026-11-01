# `html_unescape(s)` (`src/unescape.bend`) replaces the character references
# in a text the way Python's `html.unescape` does, which follows the HTML
# Standard's character reference states (§13.2.5.72 to §13.2.5.80) and keeps
# its own choices where the tokenizer would report a parse error.
#
# For every string, `html_unescape` reads it left to right and writes every
# character as itself except where `&` opens a reference: `&#` and one or
# more decimal digits, or `&#x` or `&#X` and one or more hex digits
# (§13.2.5.75 to .78), then an optional `;`, is a numeric reference
# (laws/NumericReferencesDecode.bend); `&` and 1 to 32 characters other than
# TAB, LF, FF, space, `<`, `&`, `#` and `;`, then an optional `;`
# (§13.2.5.73), is a named reference
# (laws/NamedReferencesLongestMatch.bend); reading goes on after the
# reference. A digit adds to the number as `n·base + d`, held at 0x110000
# (`grow`). An `&`, `&#` or `&#x` that opens no reference is written as it
# is.
import Base
import ../src/unescape.bend as Ref

# --- HTML character references ---

# LAW: html_unescape scans a text from text
law ref_unescape:
  for s: String
  {Ref.unescape(s) == Ref.scan(s, Ref.Txt{}) : String}

# LAW: at the end of the text, what is open ends there
law ref_scan_nil:
  for st: Ref.Scan
  {Ref.scan("", st) == Ref.end(st) : String}

# LAW: the text is scanned one character at a time
law ref_scan_cons:
  for +c: Char
  for t: String
  for st: Ref.Scan
  {Ref.scan(SCon{c, t}, st) == Ref.step(st, c, st2 => Ref.scan(t, st2))
    : String}

# LAW: in text, `&` may open a reference
law ref_text_amp:
  for +c: Char
  for k: Ref.Scan -> String
  for e: {True{} == Char.is_eq(c, '&') : Bool}
  {Ref.step(Ref.Txt{}, c, k) == k(Ref.Amp{}) : String}

# LAW: in text, every other character is itself
law ref_text_other:
  for +c: Char
  for k: Ref.Scan -> String
  for e: {False{} == Char.is_eq(c, '&') : Bool}
  {Ref.step(Ref.Txt{}, c, k) == SCon{c, k(Ref.Txt{})} : String}

# LAW (§13.2.5.72): after `&`, `#` opens a number
law ref_amp_hash:
  for +c: Char
  for k: Ref.Scan -> String
  for e: {True{} == Char.is_eq(c, '#') : Bool}
  {Ref.step(Ref.Amp{}, c, k) == k(Ref.Hash{}) : String}

# LAW (§13.2.5.73): after `&`, a name character opens a name
law ref_amp_name:
  for +c: Char
  for k: Ref.Scan -> String
  for e1: {False{} == Char.is_eq(c, '#') : Bool}
  for e2: {True{} == Ref.name.char(c) : Bool}
  {Ref.step(Ref.Amp{}, c, k) == k(Ref.Name{SCon{c, ""}, 1n}) : String}

# LAW: after `&`, anything else leaves the `&` as text and is read in text
law ref_amp_other:
  for +c: Char
  for k: Ref.Scan -> String
  for e1: {False{} == Char.is_eq(c, '#') : Bool}
  for e2: {False{} == Ref.name.char(c) : Bool}
  {Ref.step(Ref.Amp{}, c, k) == SCon{'&', Ref.step(Ref.Txt{}, c, k)}
    : String}

# LAW (§13.2.5.78): after `&#`, a decimal digit opens a decimal number
law ref_hash_dec:
  for +c: Char
  for k: Ref.Scan -> String
  for e: {True{} == U32.is_lt(Ref.digit(False{}, c), 16) : Bool}
  {Ref.step(Ref.Hash{}, c, k) == k(Ref.Num{False{}, Ref.digit(False{}, c)})
    : String}

# LAW (§13.2.5.76): after `&#`, `x` or `X` may open a hex number
law ref_hash_x:
  for +c: Char
  for k: Ref.Scan -> String
  for e1: {False{} == U32.is_lt(Ref.digit(False{}, c), 16) : Bool}
  for e2: {True{} == Bool.or(Char.is_eq(c, 'x'), Char.is_eq(c, 'X')) : Bool}
  {Ref.step(Ref.Hash{}, c, k) == k(Ref.HashX{c}) : String}

# LAW: after `&#`, anything else leaves `&#` as text and is read in text
law ref_hash_other:
  for +c: Char
  for k: Ref.Scan -> String
  for e1: {False{} == U32.is_lt(Ref.digit(False{}, c), 16) : Bool}
  for e2: {False{} == Bool.or(Char.is_eq(c, 'x'), Char.is_eq(c, 'X')) : Bool}
  {Ref.step(Ref.Hash{}, c, k) == "&#" ++ Ref.step(Ref.Txt{}, c, k) : String}

# LAW (§13.2.5.77): after `&#x`, a hex digit opens a hex number
law ref_hashx_digit:
  for +x: Char
  for +c: Char
  for k: Ref.Scan -> String
  for e: {True{} == U32.is_lt(Ref.digit(True{}, c), 16) : Bool}
  {Ref.step(Ref.HashX{x}, c, k) == k(Ref.Num{True{}, Ref.digit(True{}, c)})
    : String}

# LAW: after `&#x`, anything else leaves `&#x` as text and is read in text
law ref_hashx_other:
  for +x: Char
  for +c: Char
  for k: Ref.Scan -> String
  for e: {False{} == U32.is_lt(Ref.digit(True{}, c), 16) : Bool}
  {Ref.step(Ref.HashX{x}, c, k)
    == SCon{'&', SCon{'#', SCon{x, Ref.step(Ref.Txt{}, c, k)}}} : String}

# LAW: inside a number, a digit of its base grows it
law ref_num_digit:
  for +hex: Bool
  for +n: U32
  for +c: Char
  for k: Ref.Scan -> String
  for e: {True{} == U32.is_lt(Ref.digit(hex, c), 16) : Bool}
  {Ref.step(Ref.Num{hex, n}, c, k)
    == k(Ref.Num{hex, Ref.grow(hex, n, Ref.digit(hex, c))}) : String}

# LAW (§13.2.5.79): inside a number, `;` ends the reference with it
law ref_num_semi:
  for +hex: Bool
  for +n: U32
  for +c: Char
  for k: Ref.Scan -> String
  for e1: {False{} == U32.is_lt(Ref.digit(hex, c), 16) : Bool}
  for e2: {True{} == Char.is_eq(c, ';') : Bool}
  {Ref.step(Ref.Num{hex, n}, c, k) == Ref.code(n) ++ k(Ref.Txt{}) : String}

# LAW: inside a number, anything else ends the reference and is read in text
law ref_num_other:
  for +hex: Bool
  for +n: U32
  for +c: Char
  for k: Ref.Scan -> String
  for e1: {False{} == U32.is_lt(Ref.digit(hex, c), 16) : Bool}
  for e2: {False{} == Char.is_eq(c, ';') : Bool}
  {Ref.step(Ref.Num{hex, n}, c, k) == Ref.code(n) ++ Ref.step(Ref.Txt{}, c, k)
    : String}

# LAW: inside a name, `;` ends the reference with it
law ref_name_semi:
  for +s: String
  for +len: Nat
  for +c: Char
  for k: Ref.Scan -> String
  for e: {True{} == Char.is_eq(c, ';') : Bool}
  {Ref.step(Ref.Name{s, len}, c, k) == Ref.named(s ++ ";") ++ k(Ref.Txt{})
    : String}

# LAW: inside a name of fewer than 32 characters, a name character joins it
law ref_name_join:
  for +s: String
  for +len: Nat
  for +c: Char
  for k: Ref.Scan -> String
  for e1: {False{} == Char.is_eq(c, ';') : Bool}
  for e2: {True{} == Bool.and(Ref.name.char(c), Nat.is_lt(len, 32n)) : Bool}
  {Ref.step(Ref.Name{s, len}, c, k) == k(Ref.Name{s ++ SCon{c, ""}, 1n+len})
    : String}

# LAW: inside a name, anything else ends the reference and is read in text
law ref_name_stop:
  for +s: String
  for +len: Nat
  for +c: Char
  for k: Ref.Scan -> String
  for e1: {False{} == Char.is_eq(c, ';') : Bool}
  for e2: {False{} == Bool.and(Ref.name.char(c), Nat.is_lt(len, 32n)) : Bool}
  {Ref.step(Ref.Name{s, len}, c, k) == Ref.named(s) ++ Ref.step(Ref.Txt{}, c, k)
    : String}

# LAW: text ends with nothing open
law ref_end_text:
  for st: Ref.Scan
  for e: {Ref.Txt{} == st : Ref.Scan}
  {Ref.end(st) == "" : String}

# LAW: an `&` at the end is text
law ref_end_amp:
  for st: Ref.Scan
  for e: {Ref.Amp{} == st : Ref.Scan}
  {Ref.end(st) == "&" : String}

# LAW: an `&#` at the end is text
law ref_end_hash:
  for st: Ref.Scan
  for e: {Ref.Hash{} == st : Ref.Scan}
  {Ref.end(st) == "&#" : String}

# LAW: an `&#x` at the end is text
law ref_end_hashx:
  for x: Char
  {Ref.end(Ref.HashX{x}) == SCon{'&', SCon{'#', SCon{x, ""}}} : String}

# LAW: a number at the end ends its reference
law ref_end_num:
  for hex: Bool
  for +n: U32
  {Ref.end(Ref.Num{hex, n}) == Ref.code(n) : String}

# LAW: a name at the end ends its reference
law ref_end_name:
  for +s: String
  for len: Nat
  {Ref.end(Ref.Name{s, len}) == Ref.named(s) : String}

# LAW (§13.2.5.73): a name character is anything but TAB, LF, FF, space, `<`,
# `&`, `#` and `;`
law ref_name_char:
  for +c: Char
  {Ref.name.char(c) == Bool.not(Bool.or(Char.is_eq(c, '\t'),
    Bool.or(Char.is_eq(c, '\n'), Bool.or(Char.is_eq(c, '\u{C}'),
      Bool.or(Char.is_eq(c, ' '), Bool.or(Char.is_eq(c, '<'),
        Bool.or(Char.is_eq(c, '&'), Bool.or(Char.is_eq(c, '#'),
          Char.is_eq(c, ';'))))))))) : Bool}

# LAW: a decimal digit `0`-`9` is worth 0 to 9
law ref_digit_dec:
  for +u: U32
  for e: {True{} == Bool.and(U32.is_le(48, u), U32.is_le(u, 57)) : Bool}
  {Ref.digit(False{}, Chr{u}) == U32.sub(u, 48) : U32}

# LAW: any other character is no decimal digit
law ref_digit_dec_none:
  for +u: U32
  for e: {False{} == Bool.and(U32.is_le(48, u), U32.is_le(u, 57)) : Bool}
  {Ref.digit(False{}, Chr{u}) == 16 : U32}

# LAW: a hex digit `0`-`9` is worth 0 to 9
law ref_digit_hex_dec:
  for +u: U32
  for e: {True{} == Bool.and(U32.is_le(48, u), U32.is_le(u, 57)) : Bool}
  {Ref.digit(True{}, Chr{u}) == U32.sub(u, 48) : U32}

# LAW: a hex digit `A`-`F` is worth 10 to 15
law ref_digit_hex_upper:
  for +u: U32
  for e1: {False{} == Bool.and(U32.is_le(48, u), U32.is_le(u, 57)) : Bool}
  for e2: {True{} == Bool.and(U32.is_le(65, u), U32.is_le(u, 70)) : Bool}
  {Ref.digit(True{}, Chr{u}) == U32.sub(u, 55) : U32}

# LAW: a hex digit `a`-`f` is worth 10 to 15
law ref_digit_hex_lower:
  for +u: U32
  for e1: {False{} == Bool.and(U32.is_le(48, u), U32.is_le(u, 57)) : Bool}
  for e2: {False{} == Bool.and(U32.is_le(65, u), U32.is_le(u, 70)) : Bool}
  for e3: {True{} == Bool.and(U32.is_le(97, u), U32.is_le(u, 102)) : Bool}
  {Ref.digit(True{}, Chr{u}) == U32.sub(u, 87) : U32}

# LAW: any other character is no hex digit
law ref_digit_hex_none:
  for +u: U32
  for e1: {False{} == Bool.and(U32.is_le(48, u), U32.is_le(u, 57)) : Bool}
  for e2: {False{} == Bool.and(U32.is_le(65, u), U32.is_le(u, 70)) : Bool}
  for e3: {False{} == Bool.and(U32.is_le(97, u), U32.is_le(u, 102)) : Bool}
  {Ref.digit(True{}, Chr{u}) == 16 : U32}

# LAW: a digit grows a number as n times the base plus the digit, held at
# 0x110000
law ref_grow:
  for +hex: Bool
  for +n: U32
  for +d: U32
  {Ref.grow(hex, n, d)
    == U32.min(U32.add(U32.mul(n, Bool.pick(U32, hex, 16, 10)), d), 1114112)
    : U32}

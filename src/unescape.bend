# ezhttp/src/unescape: HTML character references back to the characters they
# stand for, the way Python's html.unescape does it (the HTML Standard's
# §13.2.5.72 to §13.2.5.80 character reference states, with Python's choices
# where the parser would report an error). Numeric references are decimal
# (`&#38;`) or hexadecimal (`&#x26;`); named ones come from the HTML
# Standard's table (src/entities.bend), the legacy names also without their
# `;`. Pure. SPEC.md HTTP-REF lists what is guaranteed.
import Base
import ./entities.bend as Ents

# where the scan stands: in text, after `&`, after `&#`, after `&#x` (the `x`
# or `X` kept), inside a number (hexadecimal or not, its value so far), or
# inside a name (its text so far and how many characters it has)
type Scan is Data:
  Txt{}
  Amp{}
  Hash{}
  HashX{x: Char}
  Num{hex: Bool, n: U32}
  Name{text: String, len: Nat}

# U+FFFD REPLACEMENT CHARACTER, alone
def fffd() -> String:
  SCon{Chr{65533}, ""}

# --- numeric references (HTTP-REF-2) ---

# the value a number is held at once it is past U+10FFFF: any larger one
# reads the same (U+FFFD)
def cap() -> U32:
  1114112

# a digit's value in a base (16 or 10), or 16 when it is not one
def digit.of(hex: Bool, +cp: U32) -> U32:
  match hex:
    case True{}:
      Bool.pick(U32, Bool.and(U32.is_le(48, cp), U32.is_le(cp, 57)),
        U32.sub(cp, 48),
        Bool.pick(U32, Bool.and(U32.is_le(65, cp), U32.is_le(cp, 70)),
          U32.sub(cp, 55),
          Bool.pick(U32, Bool.and(U32.is_le(97, cp), U32.is_le(cp, 102)),
            U32.sub(cp, 87), 16)))
    case False{}:
      Bool.pick(U32, Bool.and(U32.is_le(48, cp), U32.is_le(cp, 57)),
        U32.sub(cp, 48), 16)

# a character's value as a digit in a base, or 16 when it is not one
def digit(hex: Bool, c: Char) -> U32:
  digit.of(hex, Char.to_u32(c))

# a number with one more digit, held at cap() once past it
def grow(hex: Bool, +n: U32, +d: U32) -> U32:
  U32.min(U32.add(U32.mul(n, Bool.pick(U32, hex, 16, 10)), d), cap())

# what 0x80 to 0x9F stand for (HTML §13.2.5.80's table: Windows-1252, the
# five it leaves undefined as themselves)
def w1252() -> List<&2, U32>:
  [8364, 129, 8218, 402, 8222, 8230, 8224, 8225, 710, 8240, 352, 8249, 338,
    141, 381, 143, 144, 8216, 8217, 8220, 8221, 8226, 8211, 8212, 732, 8482,
    353, 8250, 339, 157, 382, 376]

# the code point at a place in a list, 65533 past its end
def nth(xs: List<&2, U32>, i: Nat) -> U32:
  match xs i:
    case [] _:
      65533
    case x <> t 0n:
      x
    case x <> t 1n+p:
      nth(t, p)

# a code point Python drops: C0 controls but TAB, LF, FF and CR, DEL and the
# C1 controls, and the noncharacters U+FDD0 to U+FDEF and U+xFFFE, U+xFFFF
def dropped(+n: U32) -> Bool:
  Bool.or(Bool.and(U32.is_le(1, n), U32.is_le(n, 8)),
    Bool.or(U32.is_eq(n, 11),
      Bool.or(Bool.and(U32.is_le(14, n), U32.is_le(n, 31)),
        Bool.or(Bool.and(U32.is_le(127, n), U32.is_le(n, 159)),
          Bool.or(Bool.and(U32.is_le(64976, n), U32.is_le(n, 65007)),
            U32.is_eq(U32.and(n, 65534), 65534))))))

# a code point in range: nothing when Python drops it, else the character
def code.kept(+n: U32, drop: Bool) -> String:
  match drop:
    case True{}:
      ""
    case False{}:
      SCon{Chr{n}, ""}

# a surrogate or a number past U+10FFFF is U+FFFD
def code.range(+n: U32, bad: Bool) -> String:
  match bad:
    case True{}:
      fffd()
    case False{}:
      code.kept(n, dropped(n))

# 0x80 to 0x9F as the table says
def code.c1(+n: U32, c1: Bool) -> String:
  match c1:
    case True{}:
      SCon{Chr{nth(w1252(), U32.to_nat(U32.sub(n, 128)))}, ""}
    case False{}:
      code.range(n, Bool.or(Bool.and(U32.is_le(55296, n), U32.is_le(n, 57343)),
        U32.is_lt(1114111, n)))

# 0x0D is a carriage return
def code.cr(+n: U32, cr: Bool) -> String:
  match cr:
    case True{}:
      "\r"
    case False{}:
      code.c1(n, Bool.and(U32.is_le(128, n), U32.is_le(n, 159)))

# 0 is U+FFFD, else on to 0x0D
def code.zero(+n: U32, zero: Bool) -> String:
  match zero:
    case True{}:
      fffd()
    case False{}:
      code.cr(n, U32.is_eq(n, 13))

# what a numeric reference stands for: 0 is U+FFFD
def code(+n: U32) -> String:
  code.zero(n, U32.is_eq(n, 0))

# --- named references (HTTP-REF-3) ---

# a name's length, or 0 for none yet
def best.len(m: Maybe<&2, Ents.Ref>) -> Nat:
  match m:
    case None{}:
      0n
    case Some{Ents.Ref{name, first, second}}:
      String.length(name)

# the better of the best so far and a name the text starts with: the longer
def best.take(best: Maybe<&2, Ents.Ref>, +r: Ents.Ref, longer: Bool)
  -> Maybe<&2, Ents.Ref>:
  match longer:
    case True{}:
      Some{r}
    case False{}:
      best

# a name the text starts with or not
def best.hit(+best: Maybe<&2, Ents.Ref>, +r: Ents.Ref, +name: String,
  hit: Bool) -> Maybe<&2, Ents.Ref>:
  match hit:
    case True{}:
      best.take(best, r, Nat.is_lt(best.len(best), String.length(name)))
    case False{}:
      best

# one table row against the best so far
def best.step(+best: Maybe<&2, Ents.Ref>, +r: Ents.Ref, +s: String)
  -> Maybe<&2, Ents.Ref>:
  match r:
    case Ents.Ref{+name, first, second}:
      best.hit(best, r, name, String.starts_with(s, name))

# the longest name in the rows that the text starts with
def best(rs: List<&2, Ents.Ref>, +s: String, +sofar: Maybe<&2, Ents.Ref>)
  -> Maybe<&2, Ents.Ref>:
  match rs:
    case []:
      sofar
    case r <> t:
      best(t, s, best.step(sofar, r, s))

# the one or two characters a row stands for
def chars(first: U32, +second: U32) -> String:
  SCon{Chr{first}, Bool.pick(String, U32.is_eq(second, 0), "",
    SCon{Chr{second}, ""})}

# a reference's text once its longest name is known: the characters, then
# the text after the name as written; with no name, `&` and the text
def named.of(m: Maybe<&2, Ents.Ref>, s: String) -> String:
  match m:
    case None{}:
      SCon{'&', s}
    case Some{Ents.Ref{+name, first, second}}:
      chars(first, second) ++ String.drop(s, String.length(name))

# a named reference's text (after the `&`, with its `;` if it has one)
def named(+s: String) -> String:
  named.of(best(Ents.table(), s, None{}), s)

# --- the scan (HTTP-REF-1) ---

# a character that may be in a name: anything but TAB, LF, FF, space, `<`,
# `&`, `#` and `;`
def name.char(+c: Char) -> Bool:
  Bool.not(Bool.or(Char.is_eq(c, '\t'), Bool.or(Char.is_eq(c, '\n'),
    Bool.or(Char.is_eq(c, '\u{C}'), Bool.or(Char.is_eq(c, ' '),
      Bool.or(Char.is_eq(c, '<'), Bool.or(Char.is_eq(c, '&'),
        Bool.or(Char.is_eq(c, '#'), Char.is_eq(c, ';')))))))))

# a character in text once it is known whether it is `&`
def text.of(+c: Char, k: Scan -> String, amp: Bool) -> String:
  match amp:
    case True{}:
      k(Amp{})
    case False{}:
      SCon{c, k(Txt{})}

# a character in text: `&` may open a reference
def text(+c: Char, k: Scan -> String) -> String:
  text.of(c, k, Char.is_eq(c, '&'))

# after `&`: a name character opens a name, else the `&` is text
def amp.name(+c: Char, k: Scan -> String, name: Bool) -> String:
  match name:
    case True{}:
      k(Name{SCon{c, ""}, 1n})
    case False{}:
      SCon{'&', text(c, k)}

# after `&`: `#` opens a number
def amp(+c: Char, k: Scan -> String, hash: Bool) -> String:
  match hash:
    case True{}:
      k(Hash{})
    case False{}:
      amp.name(c, k, name.char(c))

# after `&#`: `x` or `X` opens a hexadecimal number
def hash.x(+c: Char, k: Scan -> String, x: Bool) -> String:
  match x:
    case True{}:
      k(HashX{c})
    case False{}:
      "&#" ++ text(c, k)

# after `&#`, once it is known whether the character is a decimal digit
def hash.dec(+c: Char, k: Scan -> String, +d: U32, digit: Bool) -> String:
  match digit:
    case True{}:
      k(Num{False{}, d})
    case False{}:
      hash.x(c, k, Bool.or(Char.is_eq(c, 'x'), Char.is_eq(c, 'X')))

# after `&#`: a decimal digit opens a decimal number
def hash(+c: Char, k: Scan -> String, +d: U32) -> String:
  hash.dec(c, k, d, U32.is_lt(d, 16))

# after `&#x`, once it is known whether the character is a hex digit
def hash.hex.of(+x: Char, +c: Char, k: Scan -> String, +d: U32, digit: Bool)
  -> String:
  match digit:
    case True{}:
      k(Num{True{}, d})
    case False{}:
      SCon{'&', SCon{'#', SCon{x, text(c, k)}}}

# after `&#x`: a hex digit opens the number, else `&#x` is text
def hash.hex(+x: Char, +c: Char, k: Scan -> String, +d: U32) -> String:
  hash.hex.of(x, c, k, d, U32.is_lt(d, 16))

# inside a number, a character that is not a digit: `;` ends the reference
# with it, anything else ends it and is text
def num.end(+n: U32, +c: Char, k: Scan -> String, semi: Bool) -> String:
  match semi:
    case True{}:
      code(n) ++ k(Txt{})
    case False{}:
      code(n) ++ text(c, k)

# inside a number: a digit grows it
def num(+hex: Bool, +n: U32, +c: Char, k: Scan -> String, +d: U32,
  digit: Bool) -> String:
  match digit:
    case True{}:
      k(Num{hex, grow(hex, n, d)})
    case False{}:
      num.end(n, c, k, Char.is_eq(c, ';'))

# inside a name, a character that does not join it: the name ends there
def name.end(+s: String, +c: Char, k: Scan -> String) -> String:
  named(s) ++ text(c, k)

# inside a name, a character that is not `;`: a name character joins it
# while it has fewer than 32
def name.more(+s: String, len: Nat, +c: Char, k: Scan -> String, join: Bool)
  -> String:
  match join:
    case True{}:
      k(Name{s ++ SCon{c, ""}, 1n+len})
    case False{}:
      name.end(s, c, k)

# inside a name: `;` ends the reference with it
def name(+s: String, +len: Nat, +c: Char, k: Scan -> String, semi: Bool)
  -> String:
  match semi:
    case True{}:
      named(s ++ ";") ++ k(Txt{})
    case False{}:
      name.more(s, len, c, k, Bool.and(name.char(c), Nat.is_lt(len, 32n)))

# one character where the scan stands
def step(st: Scan, +c: Char, k: Scan -> String) -> String:
  match st:
    case Txt{}:
      text(c, k)
    case Amp{}:
      amp(c, k, Char.is_eq(c, '#'))
    case Hash{}:
      hash(c, k, digit(False{}, c))
    case HashX{x}:
      hash.hex(x, c, k, digit(True{}, c))
    case Num{+hex, n}:
      num(hex, n, c, k, digit(hex, c), U32.is_lt(digit(hex, c), 16))
    case Name{s, len}:
      name(s, len, c, k, Char.is_eq(c, ';'))

# the end of the text: a reference left open ends there, an `&`, `&#` or
# `&#x` with nothing after it is text
def end(st: Scan) -> String:
  match st:
    case Txt{}:
      ""
    case Amp{}:
      "&"
    case Hash{}:
      "&#"
    case HashX{x}:
      SCon{'&', SCon{'#', SCon{x, ""}}}
    case Num{hex, n}:
      code(n)
    case Name{s, len}:
      named(s)

# a text scanned from where it stands, character by character
def scan(s: String, st: Scan) -> String:
  match s:
    case SNil{}:
      end(st)
    case SCon{+c, t}:
      step(st, c, st2 => scan(t, st2))

# a text with its character references replaced, as html.unescape
def unescape(s: String) -> String:
  scan(s, Txt{})

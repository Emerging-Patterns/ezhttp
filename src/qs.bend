# ezhttp/src/qs: percent-decoding (RFC 3986 §2.1) and query strings
# (application/x-www-form-urlencoded, WHATWG URL §5), the way Python's
# urllib.parse.unquote, unquote_plus, quote_plus, urlencode and
# parse_qsl(keep_blank_values=True) do them. Decoded bytes are read as UTF-8
# (RFC 3629 §4), each maximal subpart of an ill-formed sequence replaced by
# one U+FFFD (Unicode §3.9), as Python's errors="replace" does. Pure.
# SPEC.md HTTP-QS lists what is guaranteed.
import Base
import ./pct.bend as Pct
import ./http.bend as Http

# a name and a value, as a query field or a cookie: a reusable pair, so a
# list of them can be looked up more than once
def Kv() -> Data:
  Sigma<&2, &2, String, _ => String>

# --- percent-decoding: text to bytes (HTTP-QS-1) ---

# one piece of a string being decoded: a byte of an ASCII run, or a
# character outside ASCII, which is kept as it is and ends the run
type Tok is Data:
  B{byte: U32}
  W{c: Char}

# where the decoding stands: in plain text, after `%`, or after `%` and one
# hex digit (kept)
type Esc is Data:
  Plain{}
  Pct{}
  Pct1{d: Char}

# whether a character is a hex digit (`0`-`9`, `A`-`F`, `a`-`f`)
def tok.hex(c: Char) -> Bool:
  U32.is_lt(Http.hex.val(c), 16)

# the byte a plain ASCII character stands for: `+` is a space when `plus`
def tok.byte(plus: Bool, +c: Char) -> U32:
  Bool.pick(U32, Bool.and(plus, Char.is_eq(c, '+')), 32, Char.to_u32(c))

# a plain ASCII character: `%` opens an escape, any other is its byte
def tok.ascii(plus: Bool, +c: Char, k: Esc -> List<&2, Tok>, pct: Bool)
  -> List<&2, Tok>:
  match pct:
    case True{}:
      k(Pct{})
    case False{}:
      B{tok.byte(plus, c)} <> k(Plain{})

# a plain character once it is known whether it is outside ASCII
def tok.wide(plus: Bool, +c: Char, k: Esc -> List<&2, Tok>, wide: Bool)
  -> List<&2, Tok>:
  match wide:
    case True{}:
      W{c} <> k(Plain{})
    case False{}:
      tok.ascii(plus, c, k, Char.is_eq(c, '%'))

# a character in plain text
def tok.plain(plus: Bool, +c: Char, k: Esc -> List<&2, Tok>) -> List<&2, Tok>:
  tok.wide(plus, c, k, U32.is_ge(Char.to_u32(c), 128))

# a character after `%`: a hex digit is kept, anything else leaves the `%`
# as written
def tok.pct(plus: Bool, +c: Char, k: Esc -> List<&2, Tok>, hex: Bool)
  -> List<&2, Tok>:
  match hex:
    case True{}:
      k(Pct1{c})
    case False{}:
      B{37} <> tok.plain(plus, c, k)

# a character after `%` and a hex digit: a second hex digit makes the byte
# they name, anything else leaves `%` and the digit as written
def tok.pct1(plus: Bool, +d: Char, +c: Char, k: Esc -> List<&2, Tok>,
  hex: Bool) -> List<&2, Tok>:
  match hex:
    case True{}:
      B{U32.add(U32.mul(Http.hex.val(d), 16), Http.hex.val(c))} <> k(Plain{})
    case False{}:
      B{37} <> (B{Char.to_u32(d)} <> tok.plain(plus, c, k))

# one character where the decoding stands
def tok.step(plus: Bool, st: Esc, +c: Char, k: Esc -> List<&2, Tok>)
  -> List<&2, Tok>:
  match st:
    case Plain{}:
      tok.plain(plus, c, k)
    case Pct{}:
      tok.pct(plus, c, k, tok.hex(c))
    case Pct1{d}:
      tok.pct1(plus, d, c, k, tok.hex(c))

# the end of the text: an escape left open is written as it stands
def tok.end(st: Esc) -> List<&2, Tok>:
  match st:
    case Plain{}:
      []
    case Pct{}:
      [B{37}]
    case Pct1{d}:
      [B{37}, B{Char.to_u32(d)}]

# a string as bytes and wide characters, character by character
def toks(s: String, +plus: Bool, st: Esc) -> List<&2, Tok>:
  match s:
    case SNil{}:
      tok.end(st)
    case SCon{+c, t}:
      tok.step(plus, st, c, st2 => toks(t, plus, st2))

# --- UTF-8 decoding with replacement (HTTP-QS-2) ---

# where the UTF-8 decoding stands: between characters, or inside a sequence
# with code point bits `cp` so far, needing a byte in lo..hi and `left` more
# continuation bytes after it
type Utf is Data:
  Idle{}
  Need{cp: U32, left: Nat, lo: U32, hi: U32}

# what a byte between characters is: ASCII, the lead of a sequence (its bits,
# then what the sequence needs next), or a byte no sequence starts with
type Lead is Data:
  Ascii{}
  Bad{}
  Opens{cp: U32, left: Nat, lo: U32, hi: U32}

# F4: the last lead, up to U+10FFFF; F5 to FF lead nothing
def lead.f4(f4: Bool) -> Lead:
  match f4:
    case True{}:
      Opens{4, 2n, 128, 143}
    case False{}:
      Bad{}

# F1 to F3, else F4 and up
def lead.f1(+b: U32, lt: Bool) -> Lead:
  match lt:
    case True{}:
      Opens{U32.and(b, 7), 2n, 128, 191}
    case False{}:
      lead.f4(U32.is_eq(b, 244))

# F0 (no overlong four-byte form), else F1 and up
def lead.f0(+b: U32, f0: Bool) -> Lead:
  match f0:
    case True{}:
      Opens{0, 2n, 144, 191}
    case False{}:
      lead.f1(b, U32.is_lt(b, 244))

# EE and EF, else F0 and up
def lead.ee(+b: U32, lt: Bool) -> Lead:
  match lt:
    case True{}:
      Opens{U32.and(b, 15), 1n, 128, 191}
    case False{}:
      lead.f0(b, U32.is_eq(b, 240))

# ED (no surrogates), else EE and up
def lead.ed(+b: U32, ed: Bool) -> Lead:
  match ed:
    case True{}:
      Opens{13, 1n, 128, 159}
    case False{}:
      lead.ee(b, U32.is_lt(b, 240))

# E1 to EC, else ED and up
def lead.e1(+b: U32, lt: Bool) -> Lead:
  match lt:
    case True{}:
      Opens{U32.and(b, 15), 1n, 128, 191}
    case False{}:
      lead.ed(b, U32.is_eq(b, 237))

# E0 (no overlong three-byte form), else E1 and up
def lead.e0(+b: U32, e0: Bool) -> Lead:
  match e0:
    case True{}:
      Opens{0, 1n, 160, 191}
    case False{}:
      lead.e1(b, U32.is_lt(b, 237))

# C2 to DF, else E0 and up
def lead.two(+b: U32, lt: Bool) -> Lead:
  match lt:
    case True{}:
      Opens{U32.and(b, 31), 0n, 128, 191}
    case False{}:
      lead.e0(b, U32.is_eq(b, 224))

# 80 to C1 (continuation bytes, overlong two-byte leads), else C2 and up
def lead.low(+b: U32, lt: Bool) -> Lead:
  match lt:
    case True{}:
      Bad{}
    case False{}:
      lead.two(b, U32.is_lt(b, 224))

# ASCII, else 80 and up
def lead.ascii(+b: U32, lt: Bool) -> Lead:
  match lt:
    case True{}:
      Ascii{}
    case False{}:
      lead.low(b, U32.is_lt(b, 194))

# what a byte between characters is (RFC 3629 §4, Unicode Table 3-7)
def lead(+b: U32) -> Lead:
  lead.ascii(b, U32.is_lt(b, 128))

# U+FFFD REPLACEMENT CHARACTER
def fffd() -> Char:
  Chr{65533}

# a continuation byte's six bits after the code point so far
def utf.add(+cp: U32, +b: U32) -> U32:
  U32.or(U32.shln(cp, 6n), U32.and(b, 63))

# a byte between characters, as its lead says
def utf.lead(+b: U32, k: Utf -> String, l: Lead) -> String:
  match l:
    case Ascii{}:
      SCon{Chr{b}, k(Idle{})}
    case Bad{}:
      SCon{fffd(), k(Idle{})}
    case Opens{cp, left, lo, hi}:
      k(Need{cp, left, lo, hi})

# a piece between characters
def utf.idle(t: Tok, k: Utf -> String) -> String:
  match t:
    case W{c}:
      SCon{c, k(Idle{})}
    case B{+b}:
      utf.lead(b, k, lead(b))

# a continuation byte that fits: the character ends, or more are needed
def utf.more(+cp: U32, left: Nat, +b: U32, k: Utf -> String) -> String:
  match left:
    case 0n:
      SCon{Chr{utf.add(cp, b)}, k(Idle{})}
    case 1n+l:
      k(Need{utf.add(cp, b), l, 128, 191})

# a byte inside a sequence: it continues it when it fits, else the sequence
# so far is one U+FFFD and the byte is read again between characters
def utf.byte(+cp: U32, left: Nat, +b: U32, k: Utf -> String, fits: Bool)
  -> String:
  match fits:
    case True{}:
      utf.more(cp, left, b, k)
    case False{}:
      SCon{fffd(), utf.lead(b, k, lead(b))}

# a piece inside a sequence: a wide character ends it unfinished
def utf.need(+cp: U32, left: Nat, +lo: U32, +hi: U32, t: Tok,
  k: Utf -> String) -> String:
  match t:
    case W{c}:
      SCon{fffd(), SCon{c, k(Idle{})}}
    case B{+b}:
      utf.byte(cp, left, b, k, Bool.and(U32.is_le(lo, b), U32.is_le(b, hi)))

# one piece where the decoding stands
def utf.step(st: Utf, t: Tok, k: Utf -> String) -> String:
  match st:
    case Idle{}:
      utf.idle(t, k)
    case Need{cp, left, lo, hi}:
      utf.need(cp, left, lo, hi, t, k)

# the end of the pieces: a sequence left unfinished is one U+FFFD
def utf.end(st: Utf) -> String:
  match st:
    case Idle{}:
      ""
    case Need{cp, left, lo, hi}:
      SCon{fffd(), ""}

# pieces as text, piece by piece
def utf.dec(ts: List<&2, Tok>, st: Utf) -> String:
  match ts:
    case []:
      utf.end(st)
    case t <> rest:
      utf.step(st, t, st2 => utf.dec(rest, st2))

# --- the decoders (HTTP-QS-1, 3) ---

# percent-decode a string, as urllib.parse.unquote
def unquote(s: String) -> String:
  utf.dec(toks(s, False{}, Plain{}), Idle{})

# percent-decode a string with `+` as a space, as urllib.parse.unquote_plus
def unquote.plus(s: String) -> String:
  utf.dec(toks(s, True{}, Plain{}), Idle{})

# --- quote_plus and urlencode (HTTP-QS-4, 5) ---

# one character: a space as `+`, any other as quote_component writes it
def plus.one(+cp: U32, rest: String, space: Bool) -> String:
  match space:
    case True{}:
      SCon{'+', rest}
    case False{}:
      Pct.one(False{}, cp, rest)

# percent-encode a string with a space as `+`, as urllib.parse.quote_plus
def quote.plus(s: String) -> String:
  match s:
    case SNil{}:
      SNil{}
    case SCon{Chr{+cp}, tail}:
      plus.one(cp, quote.plus(tail), U32.is_eq(cp, 32))

# one name and value as `name=value`, both quote_plus'd
def form.pair(name: String, value: String) -> String:
  quote.plus(name) ++ "=" ++ quote.plus(value)

# the pairs after the first, each after an `&`
def form.more(ps: List<&2, Kv()>) -> String:
  match ps:
    case []:
      ""
    case (name, value) <> t:
      "&" ++ form.pair(name, value) ++ form.more(t)

# pairs as a query string, as urllib.parse.urlencode
def urlencode(ps: List<&2, Kv()>) -> String:
  match ps:
    case []:
      ""
    case (name, value) <> t:
      form.pair(name, value) ++ form.more(t)

# --- parse_query and query_get (HTTP-QS-6, 7) ---

# one character put back in front of what the rest of the cut found
def cut.push(+c: Char, m: Maybe<&2, Kv()>) -> Maybe<&2, Kv()>:
  match m:
    case None{}:
      None{}
    case Some{(before, after)}:
      Some{(SCon{c, before}, after)}

# one character of the cut: the first `=` ends the text before it
def cut.at(+c: Char, t: String, eq: Bool, rest: Unit -> Maybe<&2, Kv()>)
  -> Maybe<&2, Kv()>:
  match eq:
    case True{}:
      Some{("", t)}
    case False{}:
      cut.push(c, rest(Unit{}))

# a string cut at its first `=`: the text before it and the text after it,
# none when it holds no `=`
def cut(s: String) -> Maybe<&2, Kv()>:
  match s:
    case SNil{}:
      None{}
    case SCon{+c, +t}:
      cut.at(c, t, Char.is_eq(c, '='), _u => cut(t))

# a field once it is cut: the name before its first `=` and the value after
# it, or all name and an empty value when it has no `=`
def field.of(m: Maybe<&2, Kv()>, whole: String) -> Kv():
  match m:
    case None{}:
      (unquote.plus(whole), "")
    case Some{(name, value)}:
      (unquote.plus(name), unquote.plus(value))

# one field as its name and value
def field(+piece: String) -> Kv():
  field.of(cut(piece), piece)

# one piece in front of the rest's fields, skipped when empty
def fields.put(+piece: String, rest: List<&2, Kv()>, empty: Bool)
  -> List<&2, Kv()>:
  match empty:
    case True{}:
      rest
    case False{}:
      field(piece) <> rest

# the pieces as fields, in order
def fields(ps: List<&2, String>) -> List<&2, Kv()>:
  match ps:
    case []:
      []
    case +p <> t:
      fields.put(p, fields(t), String.is_empty(p))

# a query string as its name and value pairs, as
# urllib.parse.parse_qsl(text, keep_blank_values=True)
def parse(text: String) -> List<&2, Kv()>:
  fields(String.split(text, '&'))

# the value a later pair gives, else this pair's when it is named
def get.pick(later: Maybe<&2, String>, value: String, hit: Bool)
  -> Maybe<&2, String>:
  match later hit:
    case Some{x} _:
      Some{x}
    case None{} True{}:
      Some{value}
    case None{} False{}:
      None{}

# the value of the last pair with this name, none when no pair has it
def get(ps: List<&2, Kv()>, +name: String) -> Maybe<&2, String>:
  match ps:
    case []:
      None{}
    case (key, value) <> t:
      get.pick(get(t, name), value, String.eq(key, name))

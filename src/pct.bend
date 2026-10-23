# ezhttp/src/pct: percent-encoding (RFC 3986 §2.1), the way Python's
# urllib.parse.quote does it. Unreserved characters (§2.3) are written as
# themselves; the path form also keeps "/"; every other character is written
# as the bytes of its UTF-8 encoding (RFC 3629 §3), each as "%" and two
# upper-case hex digits. SPEC.md HTTP-URL lists what is guaranteed.
import Base

# RFC 3986 §2.3 unreserved: ALPHA / DIGIT / "-" / "." / "_" / "~"
def unreserved(+cp: U32) -> Bool:
  Bool.or(Bool.and(U32.is_le(65, cp), U32.is_le(cp, 90)),
    Bool.or(Bool.and(U32.is_le(97, cp), U32.is_le(cp, 122)),
      Bool.or(Bool.and(U32.is_le(48, cp), U32.is_le(cp, 57)),
        Bool.or(U32.is_eq(cp, 45),
          Bool.or(U32.is_eq(cp, 46),
            Bool.or(U32.is_eq(cp, 95), U32.is_eq(cp, 126)))))))

# a character a form writes as itself: unreserved, or "/" when `slash` (the
# path form) keeps it
def safe(slash: Bool, +cp: U32) -> Bool:
  Bool.or(unreserved(cp), Bool.and(U32.is_eq(cp, 47), slash))

# one hex digit, upper case: 0-9 then A-F ('A' is 55 + 10)
def hex(+nib: U32) -> Char:
  Chr{Bool.pick(U32, U32.is_lt(nib, 10), U32.add(48, nib), U32.add(55, nib))}

# bytes as %XX triples, high nibble first, followed by `rest`
def pct(bytes: List<&2, U32>, rest: String) -> String:
  match bytes:
    case []:
      rest
    case +byte <> tail:
      SCon{'%', SCon{hex(U32.shrn(byte, 4n)), SCon{hex(U32.and(byte, 15)),
        pct(tail, rest)}}}

# a continuation byte: 10xxxxxx from the six bits at `shift`
def cont(+cp: U32, shift: Nat) -> U32:
  U32.or(128, U32.and(U32.shrn(cp, shift), 63))

# four bytes: U+10000 to U+10FFFF
def utf8.four(+cp: U32) -> List<&2, U32>:
  [U32.or(240, U32.shrn(cp, 18n)), cont(cp, 12n), cont(cp, 6n), cont(cp, 0n)]

# three bytes below U+10000, else four
def utf8.three(+cp: U32, fits: Bool) -> List<&2, U32>:
  match fits:
    case True{}:
      [U32.or(224, U32.shrn(cp, 12n)), cont(cp, 6n), cont(cp, 0n)]
    case False{}:
      utf8.four(cp)

# two bytes below U+0800, else more
def utf8.two(+cp: U32, fits: Bool) -> List<&2, U32>:
  match fits:
    case True{}:
      [U32.or(192, U32.shrn(cp, 6n)), cont(cp, 0n)]
    case False{}:
      utf8.three(cp, U32.is_lt(cp, 65536))

# one byte below U+0080, else more
def utf8.one(+cp: U32, fits: Bool) -> List<&2, U32>:
  match fits:
    case True{}:
      [cp]
    case False{}:
      utf8.two(cp, U32.is_lt(cp, 2048))

# the UTF-8 bytes of one code point, in order (RFC 3629 §3)
def utf8(+cp: U32) -> List<&2, U32>:
  utf8.one(cp, U32.is_lt(cp, 128))

# one character, once it is known whether the form keeps it
def one.of(+cp: U32, rest: String, kept: Bool) -> String:
  match kept:
    case True{}:
      SCon{Chr{cp}, rest}
    case False{}:
      pct(utf8(cp), rest)

# one character as the form writes it, followed by `rest`
def one(slash: Bool, +cp: U32, rest: String) -> String:
  one.of(cp, rest, safe(slash, cp))

# a string as the form writes it: each character in turn
def quote(+slash: Bool, shift: String) -> String:
  match shift:
    case SNil{}:
      SNil{}
    case SCon{Chr{+cp}, tail}:
      one(slash, cp, quote(slash, tail))

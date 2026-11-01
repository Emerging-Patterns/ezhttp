# `quote_path(s)` and `quote_component(s)` (`src/pct.bend`) percent-encode a
# string as RFC 3986 §2.1 describes, the way Python's
# `urllib.parse.quote(s)` and `urllib.parse.quote(s, safe="")` do. A
# character is a Unicode scalar value (U+0000 to U+10FFFF, no surrogates).
# Its UTF-8 encoding is the one RFC 3629 §3 tabulates.
#
# For every string, both forms write its characters in order, each one
# independently of the others; an unreserved character (RFC 3986 §2.3:
# `A`-`Z`, `a`-`z`, `0`-`9`, `-`, `.`, `_`, `~`) is written as itself.
import Base
import ../src/pct.bend as Pct

# --- percent-encoding ---

# LAW: the empty string is written as the empty string, in both forms
law quote_nil:
  for +slash: Bool
  {Pct.quote(slash, "") == "" : String}

# LAW: a string is written one character at a time, the first character's
# writing followed by the rest's
law quote_cons:
  for +slash: Bool
  for +c: U32
  for t: String
  {Pct.quote(slash, SCon{Chr{c}, t})
    == Pct.one(slash, c, Pct.quote(slash, t)) : String}

# LAW (RFC 3986 §2.3): an unreserved character is written as itself
law one_unreserved:
  for slash: Bool
  for +c: U32
  for e: {True{} == Pct.unreserved(c) : Bool}
  for rest: String
  {Pct.one(slash, c, rest) == SCon{Chr{c}, rest} : String}

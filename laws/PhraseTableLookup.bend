# A code's text in a table of (code, text) entries (`reason.in`) is the
# first entry's for that code, and empty when no entry is for it. The
# reason phrases and the errno names are both read from such a table.
import Base
import ../src/http.bend as Http

# LAW: a list with no entries gives every status the empty phrase
law reason_in_nil:
  for +code: U32
  {Http.reason.in([], code) == "" : String}

# LAW: a list gives a status its first entry's phrase when that entry is for
# that status
law reason_in_hit:
  for +code: U32
  for c: U32
  for text: String
  for t: List<&2, Http.Phrase>
  for e: {True{} == U32.is_eq(code, c) : Bool}
  {Http.reason.in(Http.P{c, text} <> t, code) == text : String}

# LAW: and the rest's phrase when it is for another status
law reason_in_miss:
  for +code: U32
  for c: U32
  for text: String
  for t: List<&2, Http.Phrase>
  for e: {False{} == U32.is_eq(code, c) : Bool}
  {Http.reason.in(Http.P{c, text} <> t, code) == Http.reason.in(t, code)
    : String}

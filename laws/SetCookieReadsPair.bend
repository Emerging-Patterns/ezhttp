# For every Set-Cookie field value (RFC 6265 §5.2): its name-value-pair is
# the text before its first `;`, all of it when it has none (step 1); a pair
# with no `=` sets nothing (step 2); otherwise the name is the text before
# its first `=` and the value the text after it (step 3), each with its
# leading and trailing SP and HTAB removed (step 4); an empty name sets
# nothing (step 5).
#
# also rests on: laws/CutAtFirstEquals.bend, laws/SplitAtCharacter.bend
import Base
import ../src/http.bend as Http
import ../src/cookie.bend as Cookie
import ../src/qs.bend as Qs
import ../src/echo.bend as Echo

# --- cookies sent back ---

# LAW (RFC 6265 §5.2 step 1): a Set-Cookie value's name-value-pair is the
# text before its first `;`, cut at its first `=`
law ck_pair:
  for line: String
  {Echo.pair(line) == Echo.pair.cut(Qs.cut(Http.first(String.split(line, ';'))))
    : Maybe<&2, Qs.Kv()>}

# LAW (§5.2 step 2): a pair with no `=` sets nothing
law ck_pair_none:
  for u: Maybe<&2, Qs.Kv()>
  for e: {None{} == u : Maybe<&2, Qs.Kv()>}
  {Echo.pair.cut(u) == None{} : Maybe<&2, Qs.Kv()>}

# LAW (§5.2 steps 3, 4): the name and the value without leading and trailing
# WSP
law ck_pair_some:
  for before: String
  for after: String
  {Echo.pair.cut(Some{(before, after)})
    == Echo.pair.named(Echo.wsp.trim(before), Echo.wsp.trim(after),
      String.is_empty(Echo.wsp.trim(before))) : Maybe<&2, Qs.Kv()>}

# LAW (§5.2 step 5): an empty name sets nothing
law ck_named_empty:
  for name: String
  for value: String
  {Echo.pair.named(name, value, True{}) == None{} : Maybe<&2, Qs.Kv()>}

# LAW: any other name sets the cookie
law ck_named_kept:
  for name: String
  for value: String
  {Echo.pair.named(name, value, False{}) == Some{(name, value)}
    : Maybe<&2, Qs.Kv()>}

# LAW: trimming strips leading WSP, then (reversed) trailing WSP
law ck_trim:
  for s: String
  {Echo.wsp.trim(s)
    == String.reverse(Echo.wsp.lead(String.reverse(Echo.wsp.lead(s))))
    : String}

# LAW: the empty string has no WSP to strip
law ck_lead_nil:
  for s: String
  for e: {"" == s : String}
  {Echo.wsp.lead(s) == "" : String}

# LAW: a leading WSP character is dropped
law ck_lead_wsp:
  for +h: Char
  for +t: String
  for e: {True{} == Echo.wsp(h) : Bool}
  {Echo.wsp.lead(SCon{h, t}) == Echo.wsp.lead(t) : String}

# LAW: stripping stops at the first other character
law ck_lead_other:
  for +h: Char
  for +t: String
  for e: {False{} == Echo.wsp(h) : Bool}
  {Echo.wsp.lead(SCon{h, t}) == SCon{h, t} : String}

# LAW (RFC 5234 WSP): whitespace is SP or HTAB
law ck_wsp:
  for +c: Char
  {Echo.wsp(c) == Bool.or(Char.is_eq(c, ' '), Char.is_eq(c, '\t')) : Bool}

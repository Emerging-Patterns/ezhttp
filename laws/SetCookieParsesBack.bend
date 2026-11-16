# For every Set-Cookie line (RFC 6265 §5.2): the line is split at `;`; the
# first piece, trimmed, is the name-value-pair, cut at its first `=` (the
# name and the value each trimmed, laws/CookieRejectsEmptyName.bend for the
# pairs that set nothing), and the cookie starts as a session cookie with
# that name and value; each further piece, trimmed, is an attribute applied
# in order: one with an `=` is a named attribute, its name trimmed and
# lowercased and its value trimmed; one without is a flag, trimmed and
# lowercased. `expires` stores the value as written, `path` the path,
# `secure` and `httponly` set their flags (Max-Age, Domain and SameSite:
# laws/CookieMaxAgeIgnoresJunk.bend, laws/CookieDomainLowercased.bend,
# laws/CookieSameSiteFoldsCase.bend). So a line written by `cookie.line`
# parses back to its cookie.
import Base
import ../src/http.bend as Http
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.2): the line split at `;`
law cookie_parse:
  for line: String
  {Cookie.cookie.parse(line)
    == Cookie.cookie.parse.parts(String.split(line, ';'))
    : Maybe<&2, Cookie.Cookie>}

# LAW (§5.2 step 1): the first piece, trimmed, cut at its first `=`
law cookie_parse_parts:
  for h: String
  for t: List<&2, String>
  {Cookie.cookie.parse.parts(h <> t)
    == Cookie.cookie.from(String.trim(h), t, Http.divide(String.trim(h), "="))
    : Maybe<&2, Cookie.Cookie>}

# LAW (§5.2 steps 3-4): the name and the value, trimmed
law cookie_from_cut:
  for pair: String
  for attrs: List<&2, String>
  for +before: String
  for after: String
  {Cookie.cookie.from(pair, attrs, Http.Cut{before, after})
    == Cookie.cookie.from.name(String.trim(before), String.trim(after), attrs,
      String.is_empty(String.trim(before))) : Maybe<&2, Cookie.Cookie>}

# LAW (§5.2 step 6): a session cookie with the attributes applied in order
law cookie_from_named:
  for name: String
  for value: String
  for attrs: List<&2, String>
  {Cookie.cookie.from.name(name, value, attrs, False{})
    == Some{Cookie.cookie.fold(attrs, Cookie.cookie.new(name, value))}
    : Maybe<&2, Cookie.Cookie>}

# LAW: a session cookie has no attributes and is host-only
law cookie_new:
  for name: String
  for value: String
  {Cookie.cookie.new(name, value)
    == Cookie.Cookie{name, value, "", "", "", "", False{}, False{}, "", True{}}
    : Cookie.Cookie}

# LAW: no attributes left, the cookie
law cookie_fold_nil:
  for ps: List<&2, String>
  for +c: Cookie.Cookie
  for e: {[] == ps : List<&2, String>}
  {Cookie.cookie.fold(ps, c) == c : Cookie.Cookie}

# LAW: each attribute, trimmed, in order
law cookie_fold_cons:
  for h: String
  for t: List<&2, String>
  for c: Cookie.Cookie
  {Cookie.cookie.fold(h <> t, c)
    == Cookie.cookie.fold(t, Cookie.cookie.apply(c, String.trim(h)))
    : Cookie.Cookie}

# LAW (§5.2): an attribute is cut at its first `=`
law cookie_apply:
  for c: Cookie.Cookie
  for +piece: String
  {Cookie.cookie.apply(c, piece)
    == Cookie.cookie.apply.cut(c, piece, Http.divide(piece, "="))
    : Cookie.Cookie}

# LAW (§5.2): with an `=`, a named attribute, name lowercased
law cookie_apply_named:
  for c: Cookie.Cookie
  for piece: String
  for before: String
  for after: String
  {Cookie.cookie.apply.cut(c, piece, Http.Cut{before, after})
    == Cookie.cookie.named(c, String.to_lower(String.trim(before)),
      String.trim(after)) : Cookie.Cookie}

# LAW (§5.2): without one, a flag, lowercased
law cookie_apply_flag:
  for c: Cookie.Cookie
  for piece: String
  {Cookie.cookie.apply.cut(c, piece, Http.NoCut{})
    == Cookie.cookie.flag(c, String.to_lower(String.trim(piece)))
    : Cookie.Cookie}

# LAW (§5.2.1): Expires is stored as written
law cookie_named_expires:
  for c: Cookie.Cookie
  for value: String
  {Cookie.cookie.named(c, "expires", value) == Cookie.cookie.expires(c, value)
    : Cookie.Cookie}

# LAW (§5.2.4): Path is stored
law cookie_named_path:
  for c: Cookie.Cookie
  for value: String
  {Cookie.cookie.named(c, "path", value) == Cookie.cookie.dir(c, value)
    : Cookie.Cookie}

# LAW (§5.2.5): the secure flag sets Secure
law cookie_flag_secure:
  for c: Cookie.Cookie
  {Cookie.cookie.flag(c, "secure") == Cookie.cookie.secure_on(c)
    : Cookie.Cookie}

# LAW (§5.2.6): the httponly flag sets HttpOnly
law cookie_flag_http_only:
  for c: Cookie.Cookie
  {Cookie.cookie.flag(c, "httponly") == Cookie.cookie.http_on(c)
    : Cookie.Cookie}

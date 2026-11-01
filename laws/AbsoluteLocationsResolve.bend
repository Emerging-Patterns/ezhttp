# A Location that starts `http://` or `https://` is its own target. Against
# a current URL that parses into scheme, host, port and path, a Location
# that starts `//` (a network-path reference) is the scheme, `:` and the
# Location; one that starts with a single `/` (an absolute path) is the
# scheme, `://`, host, `:`, port, then its path with dot segments removed
# (laws/DotSegmentsRemoved.bend) and its query after it unchanged, its
# fragment dropped. An empty Location, one that starts `#`, one whose text
# before its first `/`, `?` or `#` holds a `:` (another scheme), and every
# other Location against a URL that does not parse have no target.
#
# also rests on: laws/LocationResolvedBySort.bend,
# laws/LocationSplitsAtQuery.bend
import Base
import ../src/url.bend as Url
import ../src/redirect.bend as Redirect

# LAW: an absolute http or https Location is its own target
law target_absolute:
  for url: String
  for +loc: String
  for e: {True{} == Bool.or(String.starts_with(loc, "http://"),
    String.starts_with(loc, "https://")) : Bool}
  {Redirect.redirect.target(url, loc) == Some{loc} : Maybe<&2, String>}

# LAW: against a URL that does not parse, a Location that is not an absolute
# URL has no target
law target_bad:
  for url: String
  for +loc: String
  for e1: {False{} == Bool.or(String.starts_with(loc, "http://"),
    String.starts_with(loc, "https://")) : Bool}
  for why: String
  for e2: {Url.Bad{why} == Url.parse(url) : Url.Loc}
  {Redirect.redirect.target(url, loc) == None{} : Maybe<&2, String>}

# LAW (RFC 3986 §5.2.2): a network-path reference keeps only the scheme
law against_net:
  for scheme: String
  for host: String
  for port: U32
  for path: String
  for +loc: String
  {Redirect.redirect.against(scheme, host, port, path, loc, Redirect.Net{})
    == Some{scheme ++ ":" ++ loc} : Maybe<&2, String>}

# LAW (RFC 3986 §5.2.2): an absolute path keeps the origin, its own path with
# dot segments removed, then its query
law against_abs:
  for scheme: String
  for host: String
  for port: U32
  for path: String
  for +loc: String
  {Redirect.redirect.against(scheme, host, port, path, loc, Redirect.Abs{})
    == Some{scheme ++ "://" ++ host ++ ":" ++ U32.show(port)
      ++ Redirect.redirect.abs.of(Redirect.redirect.split(loc))}
    : Maybe<&2, String>}

# LAW: a Location the client stays on has no target
law against_stay:
  for scheme: String
  for host: String
  for port: U32
  for path: String
  for +loc: String
  {Redirect.redirect.against(scheme, host, port, path, loc, Redirect.Stay{})
    == None{} : Maybe<&2, String>}

# LAW (RFC 3986 §4.2): a Location that starts `//` is a network path
law sort_net:
  for +loc: String
  for e: {True{} == String.starts_with(loc, "//") : Bool}
  {Redirect.redirect.sort(loc) == Redirect.Net{} : Redirect.Sort}

# LAW (RFC 3986 §4.2): one that starts with a single `/` is an absolute path
law sort_abs:
  for +loc: String
  for e1: {False{} == String.starts_with(loc, "//") : Bool}
  for e2: {True{} == String.starts_with(loc, "/") : Bool}
  {Redirect.redirect.sort(loc) == Redirect.Abs{} : Redirect.Sort}

# LAW: any other Location the client does not follow stays
law sort_stay:
  for +loc: String
  for e1: {False{} == String.starts_with(loc, "//") : Bool}
  for e2: {False{} == String.starts_with(loc, "/") : Bool}
  for e3: {True{} == Redirect.redirect.stays(loc) : Bool}
  {Redirect.redirect.sort(loc) == Redirect.Stay{} : Redirect.Sort}

# LAW: the client stays on an empty Location, a fragment, and one that names
# another scheme
law stays_on:
  for +loc: String
  {Redirect.redirect.stays(loc) == Bool.or(String.is_empty(loc),
    Bool.or(String.starts_with(loc, "#"), Redirect.redirect.schemed(loc)))
    : Bool}

# LAW (RFC 3986 §3.1): an empty reference names no scheme
law schemed_nil:
  for s: String
  for e: {True{} == String.is_empty(s) : Bool}
  {Redirect.redirect.schemed(s) == False{} : Bool}

# LAW (RFC 3986 §3.1): a `:` before the first `/`, `?` or `#` names a scheme
law schemed_colon:
  for t: String
  {Redirect.redirect.schemed(SCon{':', t}) == True{} : Bool}

# LAW (RFC 3986 §4.2): a `/`, `?` or `#` first means no scheme
law schemed_stop:
  for +c: Char
  for t: String
  for e: {True{} == Redirect.redirect.schemed.end(c) : Bool}
  {Redirect.redirect.schemed(SCon{c, t}) == False{} : Bool}

# LAW: any other first character leaves the question to the rest
law schemed_other:
  for +c: Char
  for t: String
  for e1: {False{} == Char.is_eq(c, ':') : Bool}
  for e2: {False{} == Redirect.redirect.schemed.end(c) : Bool}
  {Redirect.redirect.schemed(SCon{c, t}) == Redirect.redirect.schemed(t)
    : Bool}

# LAW: the characters that end a reference's first segment are `/`, `?`, `#`
law schemed_end:
  for +c: Char
  {Redirect.redirect.schemed.end(c) == Bool.or(Char.is_eq(c, '/'),
    Bool.or(Char.is_eq(c, '?'), Char.is_eq(c, '#'))) : Bool}

# LAW (RFC 3986 §5.2.2): an absolute path is its segments after the leading
# `/`, dot segments removed, then its query
law abs_of:
  for path: String
  for query: String
  {Redirect.redirect.abs.of(Redirect.Ref{path, query})
    == Redirect.redirect.clean(List.tail(&2, String, String.split(path, '/')))
      ++ query : String}

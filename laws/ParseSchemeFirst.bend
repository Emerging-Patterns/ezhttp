import Base
import ../src/url.bend as Url

# LAW (RFC 3986 §3.1): the scheme is everything before the first colon
law parse_scheme_first:
  for +url: String
  for h: String
  for t: List<&2, String>
  for e: {h <> t == String.split(url, ':') : List<&2, String>}
  {Url.parse(url) == Url.parse.rest(String.to_lower(h), String.join(t, ":"))
    : Url.Loc}

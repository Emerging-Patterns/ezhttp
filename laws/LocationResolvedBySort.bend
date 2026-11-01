# Against a URL that parses, a Location that is not an absolute `http://`
# or `https://` URL is resolved by its sort against the URL's scheme, host,
# port and path (RFC 3986 §5.2.2).
import Base
import ../src/url.bend as Url
import ../src/redirect.bend as Redirect

# LAW (RFC 3986 §5.2.2): against a URL that parses, a Location that is not an
# absolute URL is resolved by its sort against the URL's parts
law target_against:
  for url: String
  for +loc: String
  for e1: {False{} == Bool.or(String.starts_with(loc, "http://"),
    String.starts_with(loc, "https://")) : Bool}
  for scheme: String
  for host: String
  for port: U32
  for path: String
  for e2: {Url.Loc{scheme, host, port, path} == Url.parse(url) : Url.Loc}
  {Redirect.redirect.target(url, loc)
    == Redirect.redirect.against(scheme, host, port, path, loc,
      Redirect.redirect.sort(loc)) : Maybe<&2, String>}

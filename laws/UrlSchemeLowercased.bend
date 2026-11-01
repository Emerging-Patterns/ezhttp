import Base
import ../src/url.bend as Url

# LAW (RFC 3986 §3.1): the scheme is lowercased; the host is not
law url_scheme_lowercased:
  {Url.parse("HTTPS://Example.com/x")
    == Url.Loc{"https", "Example.com", 443, "/x"} : Url.Loc}

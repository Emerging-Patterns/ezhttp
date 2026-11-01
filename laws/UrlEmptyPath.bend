import Base
import ../src/url.bend as Url

# --- RFC 3986 authority, query, fragment ---

# LAW (RFC 3986 §3.3): an empty path-abempty is the origin-form `/`
law url_empty_path:
  {Url.parse("http://example.com")
    == Url.Loc{"http", "example.com", 80, "/"} : Url.Loc}

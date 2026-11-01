import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §4.1.1): SameSite=none is canonical None
law cookie_samesite_none:
  {Cookie.cookie.parse("a=b; SameSite=none")
    == Some{Cookie.Cookie{"a", "b", "", "", "", "", False{}, False{},
      "None", True{}}} : Maybe<&2, Cookie.Cookie>}

import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §4.1.1): SameSite=STRICT is canonical Strict
law cookie_samesite_strict:
  {Cookie.cookie.parse("a=b; SameSite=STRICT")
    == Some{Cookie.Cookie{"a", "b", "", "", "", "", False{}, False{},
      "Strict", True{}}} : Maybe<&2, Cookie.Cookie>}

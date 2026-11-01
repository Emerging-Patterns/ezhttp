import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.2.3): a Domain attribute is stored lowercase
law cookie_domain_lowercased:
  {Cookie.cookie.parse("a=b; Domain=Example.COM")
    == Some{Cookie.Cookie{"a", "b", "", "", "example.com", "", False{},
      False{}, "", False{}}} : Maybe<&2, Cookie.Cookie>}

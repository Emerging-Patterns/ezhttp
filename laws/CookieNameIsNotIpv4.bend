# For every host, a character that is neither `.` nor a decimal digit,
# anywhere in it, makes it not an IPv4 literal, so `example.com` is not one
# (RFC 6265 §5.1.3); the rest of the scan is laws/CookieRecognizesIpv4Literal.bend.
import Base
import ../src/cookie.bend as Cookie

# LAW: any other character, not an IPv4 literal
law cookie_ipv4_other:
  for +h: Char
  for t: String
  for seen: Bool
  for e1: {False{} == U32.is_eq(Char.to_u32(h), 46) : Bool}
  for e2: {False{} == Bool.and(U32.is_ge(Char.to_u32(h), 48),
    U32.is_le(Char.to_u32(h), 57)) : Bool}
  {Cookie.cookie.ipv4.go(SCon{h, t}, seen) == False{} : Bool}

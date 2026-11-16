# For every host, `cookie.ipv4` scans it from the start: a `.` goes on and
# notes that a dot was seen, a decimal digit goes on, any other character
# says it is not an IPv4 literal, and the end says whether a dot was seen;
# so a host of digits and dots with a dot, such as `192.0.2.1`, is one
# (RFC 6265 §5.1.3, no subdomain match for an IP address).
import Base
import ../src/cookie.bend as Cookie

# LAW: the scan starts with no dot seen
law cookie_ipv4:
  for host: String
  {Cookie.cookie.ipv4(host) == Cookie.cookie.ipv4.go(host, False{}) : Bool}

# LAW: at the end, an IPv4 literal when a dot was seen
law cookie_ipv4_end:
  for +seen: Bool
  {Cookie.cookie.ipv4.go("", seen) == seen : Bool}

# LAW: a dot goes on, a dot seen
law cookie_ipv4_dot:
  for +t: String
  for seen: Bool
  {Cookie.cookie.ipv4.go(SCon{'.', t}, seen)
    == Cookie.cookie.ipv4.go(t, True{}) : Bool}

# LAW: a decimal digit goes on
law cookie_ipv4_digit:
  for +h: Char
  for +t: String
  for +seen: Bool
  for e1: {False{} == U32.is_eq(Char.to_u32(h), 46) : Bool}
  for e2: {True{} == Bool.and(U32.is_ge(Char.to_u32(h), 48),
    U32.is_le(Char.to_u32(h), 57)) : Bool}
  {Cookie.cookie.ipv4.go(SCon{h, t}, seen) == Cookie.cookie.ipv4.go(t, seen)
    : Bool}

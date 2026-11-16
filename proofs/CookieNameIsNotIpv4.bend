# proofs of laws/CookieNameIsNotIpv4.bend
import Base
import ../src/cookie.bend as Cookie
import ../laws/CookieNameIsNotIpv4.bend as Laws

def Laws.cookie_ipv4_other(h, t, seen, e1, e2):
  match h:
    case Chr{+x}:
      %e1 : {Cookie.cookie.ipv4.step(_, Bool.and(U32.is_ge(x, 48), U32.is_le(x, 57)),
        _u => Cookie.cookie.ipv4.go(t, True{}), _d => Cookie.cookie.ipv4.go(t, seen))
        == False{} : Bool}
      %e2 : {Cookie.cookie.ipv4.step(False{}, _,
        _u => Cookie.cookie.ipv4.go(t, True{}), _d => Cookie.cookie.ipv4.go(t, seen))
        == False{} : Bool}
      {==}

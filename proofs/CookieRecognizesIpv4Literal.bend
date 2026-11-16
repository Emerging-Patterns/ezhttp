# proofs of laws/CookieRecognizesIpv4Literal.bend
import Base
import ../src/cookie.bend as Cookie
import ../laws/CookieRecognizesIpv4Literal.bend as Laws

def Laws.cookie_ipv4(_host):
  {==}

def Laws.cookie_ipv4_end(_seen):
  {==}

def Laws.cookie_ipv4_dot(_t, _seen):
  {==}

def Laws.cookie_ipv4_digit(h, t, seen, e1, e2):
  match h:
    case Chr{+x}:
      %e1 : {Cookie.cookie.ipv4.step(_, Bool.and(U32.is_ge(x, 48), U32.is_le(x, 57)),
        _u => Cookie.cookie.ipv4.go(t, True{}), _d => Cookie.cookie.ipv4.go(t, seen))
        == Cookie.cookie.ipv4.go(t, seen) : Bool}
      %e2 : {Cookie.cookie.ipv4.step(False{}, _,
        _u => Cookie.cookie.ipv4.go(t, True{}), _d => Cookie.cookie.ipv4.go(t, seen))
        == Cookie.cookie.ipv4.go(t, seen) : Bool}
      {==}

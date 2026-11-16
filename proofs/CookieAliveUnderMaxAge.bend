# proofs of laws/CookieAliveUnderMaxAge.bend
import Base
import ../src/cookie.bend as Cookie
import ../laws/CookieAliveUnderMaxAge.bend as Laws

def Laws.cookie_alive_max_age(_max_age, n, age, e):
  %e : {Cookie.cookie.alive.of(age, _) == Nat.is_lt(age, n) : Bool}
  {==}

def Laws.cookie_alive_session(_max_age, age, e):
  %e : {Cookie.cookie.alive.of(age, _) == True{} : Bool}
  {==}

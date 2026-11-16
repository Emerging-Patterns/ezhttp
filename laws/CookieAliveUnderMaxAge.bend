# For every Max-Age text and age in seconds: a Max-Age that reads as the
# decimal digits of n keeps the cookie alive exactly while its age is below n
# (so Max-Age=0 is never alive and Max-Age=1 is alive at 0 s, not at 1 s),
# and a Max-Age that is not digits (absent, a session cookie, or junk)
# leaves it alive (RFC 6265 §5.2.2, §5.3 step 3).
import Base
import ../src/http.bend as Http
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.2.2): alive while the age is below Max-Age
law cookie_alive_max_age:
  for max_age: String
  for +n: Nat
  for +age: Nat
  for e: {Some{n} == Http.digits.read(max_age) : Maybe<&2, Nat>}
  {Cookie.cookie.alive(max_age, age) == Nat.is_lt(age, n) : Bool}

# LAW (§5.3 step 3): no Max-Age digits, a session cookie, alive
law cookie_alive_session:
  for max_age: String
  for +age: Nat
  for e: {None{} == Http.digits.read(max_age) : Maybe<&2, Nat>}
  {Cookie.cookie.alive(max_age, age) == True{} : Bool}

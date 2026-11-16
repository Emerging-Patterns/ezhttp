# For every reading so far `acc`, digits still allowed `1n+k`, character `c`
# that is not a decimal digit and text `t` after it, the Content-Length
# reader (`digits.go`) reads nothing (RFC 9110 §8.6: Content-Length =
# 1*DIGIT, so a value with any other character is not a length).
import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §8.6): a character that is not a digit leaves no length
law digits_junk:
  for c: Char
  for t: String
  for acc: Nat
  for k: Nat
  for e: {False{} == U32.is_lt(Http.digits.val(c), 10) : Bool}
  {Http.digits.go(SCon{c, t}, acc, 1n+k) == None{} : Maybe<&2, Nat>}

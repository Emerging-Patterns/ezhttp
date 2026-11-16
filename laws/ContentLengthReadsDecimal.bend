# For every reading so far `acc`, digits still allowed `1n+k`, digit `c` and
# text `t` after it, the Content-Length reader (`digits.go`) takes a decimal
# digit as ten times what it read so far plus the digit's value and reads
# on, and at the end of the text with digits still allowed it has read
# `acc` (RFC 9110 §8.6: Content-Length = 1*DIGIT, a decimal count).
import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §8.6): a decimal digit is ten times the reading so far plus
# its value
law digits_step:
  for c: Char
  for t: String
  for +acc: Nat
  for k: Nat
  for e: {True{} == U32.is_lt(Http.digits.val(c), 10) : Bool}
  {Http.digits.go(SCon{c, t}, acc, 1n+k)
    == Http.digits.go(t, Nat.add(Nat.mul(acc, 10n), U32.to_nat(Http.digits.val(c))), k)
    : Maybe<&2, Nat>}

# LAW (RFC 9110 §8.6): at the end of the digits the reading is the number
law digits_end:
  for acc: Nat
  for k: Nat
  {Http.digits.go("", acc, 1n+k) == Some{acc} : Maybe<&2, Nat>}

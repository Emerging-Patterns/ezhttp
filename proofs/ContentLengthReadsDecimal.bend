# proofs of laws/ContentLengthReadsDecimal.bend
import Base
import ../src/http.bend as Http
import ../laws/ContentLengthReadsDecimal.bend as Laws

def Laws.digits_step(c, t, acc, k, e):
  %e : {Http.digits.step(_, _u => Http.digits.go(t, Nat.add(Nat.mul(acc, 10n),
    U32.to_nat(Http.digits.val(c))), k))
    == Http.digits.go(t, Nat.add(Nat.mul(acc, 10n), U32.to_nat(Http.digits.val(c))), k)
    : Maybe<&2, Nat>}
  {==}

def Laws.digits_end(_acc, _k):
  {==}

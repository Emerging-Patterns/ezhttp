import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §6.3): Content-Length is a decimal, not a prefix of junk
law digits_read_decimal:
  {Http.digits.read("12") == Some{12n} : Maybe<&2, Nat>}

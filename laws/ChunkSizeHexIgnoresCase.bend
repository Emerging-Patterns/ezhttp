import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §7.1): `a` and `A` are the same chunk-size digit
law hexlen_alpha:
  {Http.hexlen("a") == Http.hexlen("A") : Nat}

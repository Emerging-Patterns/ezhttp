import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §6.3): a Content-Length that is not all digits is absent
law digits_read_rejects_junk:
  {Http.digits.read("12a") == None{} : Maybe<&2, Nat>}

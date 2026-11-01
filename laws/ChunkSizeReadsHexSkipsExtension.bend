import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §7.1): chunk-size is hexadecimal, and an extension is skipped
law hexlen_extension_and_case:
  {Http.hexlen("5;ext=1") == 5n : Nat}

import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §7.1): no fuel left means no more chunks
law chunks_empty_fuel:
  {Http.chunks(0n, Http.NoCut{}) == "" : String}

# For every cut `c` and fuel `f`, the chunked decoder (`chunks`) writes
# nothing once its fuel is spent, and nothing when no CRLF is left to end a
# chunk-size line (RFC 9112 §7.1: a chunk-size line ends with CRLF).
import Base
import ../src/http.bend as Http

# LAW: with no fuel left the decoder writes nothing
law chunks_no_fuel:
  for c: Http.Cut
  {Http.chunks(0n, c) == "" : String}

# LAW (RFC 9112 §7.1): with no chunk-size line left the decoder writes nothing
law chunks_no_cut:
  for f: Nat
  {Http.chunks(f, Http.NoCut{}) == "" : String}

# For every status, header fields and chunked body of at least one
# character whose first chunk-size line `before` (up to the first CRLF) is
# not hexadecimal digits once its extensions are removed, the response is
# torn with `chunk size is not hexadecimal` (RFC 9112 §7.1: chunk-size is
# 1*HEXDIG).
import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §7.1): a chunk size that is not hex tears the response
law chunked_non_hex:
  for st: U32
  for hs: List<&2, Http.Header>
  for +body: String
  for f: Nat
  for +before: String
  for +after: String
  for el: {1n+f == String.length(body) : Nat}
  for e: {Http.Cut{before, after} == Http.divide(body, "\r\n") : Http.Cut}
  for eh: {False{} == Http.hex.well(Http.chunks.token(before)) : Bool}
  {Http.parse.chunks(st, hs, body) == Http.Torn{"chunk size is not hexadecimal"}
    : Http.Reply}

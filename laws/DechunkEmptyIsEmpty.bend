# For every body `s` with no CRLF in it, the chunked decoder (`dechunk`)
# reads it as no octets: without a CRLF there is no chunk-size line (RFC 9112
# §7.1), and the empty body is one such body.
import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §7.1): a body with no CRLF decodes to nothing
law dechunk_no_crlf:
  for +s: String
  for e: {Http.NoCut{} == Http.divide(s, "\r\n") : Http.Cut}
  {Http.dechunk(s) == "" : String}

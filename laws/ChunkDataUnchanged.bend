# For every chunk-size line `h` that is a hexadecimal size `n` other than 0,
# its `n` octets of data `d` and the text `r` after the CRLF that ends them,
# the chunked decoder writes exactly `d`, then what it decodes from `r` (RFC
# 9112 §7.1: a chunk's data is its octets, unchanged); a chunk-size line
# whose size is 0 ends the body.
import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §7.1): a chunk of n octets other than 0 is its data, then
# the chunks after its CRLF
law chunk_data:
  for f: Nat
  for +h: String
  for +d: String
  for +r: String
  for e: {False{} == Nat.is_eq(Http.hexlen(h), 0n) : Bool}
  for el: {String.length(d) == Http.hexlen(h) : Nat}
  {Http.chunks(1n+f, Http.Cut{h, String.append(d, "\r\n" ++ r)})
    == String.append(d, Http.chunks(f, Http.divide(r, "\r\n"))) : String}

# LAW (RFC 9112 §7.1): a chunk of size 0 ends the body
law chunk_last:
  for f: Nat
  for +h: String
  for after: String
  for e: {True{} == Nat.is_eq(Http.hexlen(h), 0n) : Bool}
  {Http.chunks(1n+f, Http.Cut{h, after}) == "" : String}

import Base
import ../src/http.bend as Http

# LAW: take and drop partition a string at the same UTF-8 byte offset
# (Content-Length octets, RFC 9110 §8.6).
law utf8_split:
  for s: String
  for +n: Nat
  {String.append(Http.octs.take(s, n), Http.octs.drop(s, n)) == s : String}

# For every method, URL that parses, headers and body, the exchange the
# client builds carries exactly that method, and the request it carries
# opens with exactly `<method> <path> HTTP/1.1` and CRLF; the client reads
# the answer by the exchange's method (laws/ResponseCompleteByFraming.bend),
# timed or not (trusted in src/client.bend).
#
# also rests on: laws/RequestLineAndHost.bend
import Base
import ../src/http.bend as Http
import ../src/url.bend as Url
import ../src/wirespec.bend as Spec

# LAW: the method the wire layer reads the answer by is the method the
# exchange was built for, for every method and every URL that parses
law exchange_method:
  for method: String
  for scheme: String
  for host: String
  for port: U32
  for path: String
  for hs: List<&2, Http.Header>
  for body: String
  {Spec.wire.exchange.method(
    Spec.wire.exchange(method, Url.Loc{scheme, host, port, path}, hs, body))
    == Some{method} : Maybe<&2, String>}

# LAW (RFC 9112 §3): for every method, the request a client writes opens with
# that method, the path and the protocol version on its request line
law request_line:
  for +method: String
  for secure: Bool
  for host: String
  for port: U32
  for +path: String
  for hs: List<&2, Http.Header>
  for +body: String
  {String.starts_with(Http.request.at(method, secure, host, port, path, hs,
    body), method ++ " " ++ path ++ " HTTP/1.1\r\n") == True{} : Bool}

# `src/wirespec.bend` decides what the client sends, when it has heard a
# whole answer, and what a failed exchange is reported as, and does no IO.
# It judges the answer read by read: the state it carries from one read to
# the next (`Http.hear`, in `src/http.bend`) is advanced by each read's text
# alone, and is proved to decide exactly what judging all the text received
# would (laws/ReadStateMatchesWholeText.bend). `wire.exchange` turns a
# method, a parsed URL, headers and a body into the scheme, host, port,
# method and request text that is sent, and `src/http.bend` decides the
# request's header fields; `src/client.bend` and `src/wire.bend` send it
# over bend-kit-wire's sockets and read the answer as it decides (trusted in
# src/wire.bend, trusted in src/client.bend). The answer is received as
# octets, one character each (laws/OneOctetPerChar.bend).
#
# An exchange's answer is the response's octets, packed, or the reason the
# exchange failed: a non-zero status on its first line, then the reason
# (laws/FailuresReportedByPhase.bend). The client judges each receive by its
# count of octets when that decides it, and by its text otherwise
# (laws/ReadsJudgedByCount.bend), plans the response from its head with
# `src/http.bend`'s decisions (laws/HeadPlannedBeforeBody.bend), and copies
# the body out of the packed octets without turning it into text (trusted in
# src/packed.bend). `http.get_opts`, `http.request_opts`, `http.post_opts`,
# `http.put_opts` and `http.delete_opts` take a timeout in milliseconds,
# which becomes the deadline of every socket call the exchange makes
# (laws/DeadlineIsTimeout.bend, laws/TimeoutZeroIsOneMs.bend).
#
# For every method, scheme, host, port, path, headers and body, the request
# the client writes for that URL is the request line `<method> <path>
# HTTP/1.1`, its header fields (laws/RequestHeaderFieldsOrdered.bend), a
# blank line and the body, and its default Host field names the host as RFC
# 9110 §7.2 asks: exactly `Host: <host>` when the port is the scheme's
# default (80 for `http`, 443 for `https`), and exactly `Host:
# <host>:<port>` for every other port. The exchange goes over TLS exactly
# when the scheme is `https`, to that host and port; a URL that does not
# parse sends nothing and is reported with its reason.
import Base
import ../src/http.bend as Http
import ../src/url.bend as Url
import ../src/wirespec.bend as Spec

# --- the client's requests ---

# LAW (RFC 9110 §7.2): on port 80 an http request's Host is the host alone
law host_http_default:
  for host: String
  {Http.authority(False{}, host, 80) == host : String}

# LAW (RFC 9110 §7.2): on port 443 an https request's Host is the host alone
law host_https_default:
  for host: String
  {Http.authority(True{}, host, 443) == host : String}

# LAW (RFC 9110 §7.2): on any other port an http request's Host is
# `host:port`
law host_http_other:
  for host: String
  for +port: U32
  for e: {False{} == U32.is_eq(port, 80) : Bool}
  {Http.authority(False{}, host, port) == host ++ ":" ++ U32.show(port)
    : String}

# LAW (RFC 9110 §7.2): on any other port an https request's Host is
# `host:port`
law host_https_other:
  for host: String
  for +port: U32
  for e: {False{} == U32.is_eq(port, 443) : Bool}
  {Http.authority(True{}, host, port) == host ++ ":" ++ U32.show(port)
    : String}

# LAW (RFC 9110 §7.2, RFC 9112 §3): the request a client writes for a host
# and port is its request line, the header fields request.fields gives for
# that Host value, a blank line and the body
law request_at:
  for +method: String
  for secure: Bool
  for host: String
  for port: U32
  for +path: String
  for hs: List<&2, Http.Header>
  for +body: String
  {Http.request.at(method, secure, host, port, path, hs, body)
    == method ++ " " ++ path ++ " HTTP/1.1\r\n"
      ++ Http.headers.lines(
        Http.request.fields(Http.authority(secure, host, port), hs, body))
      ++ "\r\n"
      ++ body
    : String}

# LAW: a URL that does not parse sends nothing and keeps its reason
law exchange_bad:
  for method: String
  for why: String
  for hs: List<&2, Http.Header>
  for body: String
  {Spec.wire.exchange(method, Url.Bad{why}, hs, body) == Spec.NoUrl{why}
    : Spec.Exchange}

# LAW: a URL that parses is sent to its host and port, over TLS exactly when
# its scheme is https, with the method it was given and the request
# request.at writes for them
law exchange_loc:
  for method: String
  for +scheme: String
  for +host: String
  for +port: U32
  for path: String
  for hs: List<&2, Http.Header>
  for body: String
  {Spec.wire.exchange(method, Url.Loc{scheme, host, port, path}, hs, body)
    == Spec.Exchange{String.eq(scheme, "https"), host, port, method,
      Http.request.at(method, String.eq(scheme, "https"), host, port, path, hs,
        body)} : Spec.Exchange}

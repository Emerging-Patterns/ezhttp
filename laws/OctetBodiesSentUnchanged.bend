# A body is split into its shape and its octets (`body.shape`): a text body
# is its text and no octets, the empty body is the empty text, and an octets
# body (`Body.Octets`, packed `Bytes`) of `n` octets is `ShapeOctets{n}` and
# those octets. For every shape, method, headers and URL that parses, a
# `ShapeOctets{n}` exchange's request text is the request line, the header
# fields laws/RequestHeaderFieldsOrdered.bend gives for a body of `n` octets
# (so its Content-Length fields are exactly `Content-Length: <n>`, and none
# when `n` is 0), and a blank line; a text exchange is the one
# laws/RequestLineAndHost.bend describes, its header fields the ones
# laws/RequestHeaderFieldsOrdered.bend gives for the text's UTF-8 octets.
# What is sent is the request text as its UTF-8 octets (`wire.payload`, RFC
# 3629 §3, each character as `Pct.utf8` writes it,
# laws/QuoteEscapesUtf8Bytes.bend), then the body's octets unchanged
# (trusted in src/wire.bend).
import Base
import ../src/http.bend as Http
import ../src/url.bend as Url
import ../src/body.bend as Body
import ../src/wirespec.bend as Spec
import ../src/pct.bend as Pct
import bend-kit-bytes@0.3.2.0/bytes.bend as Bytes

# --- octet bodies on the wire ---

# LAW: a text body is sent inside the request text, as
# laws/RequestLineAndHost.bend says
law exchange_body_text:
  for method: String
  for l: Url.Loc
  for hs: List<&2, Http.Header>
  for text: String
  {Spec.wire.exchange.body(method, l, hs,
    Pair.fst(Body.Shape, Bytes.Bytes, Body.body.shape(Body.Plain{text})))
    == Spec.wire.exchange(method, l, hs, text) : Spec.Exchange}

# LAW: an empty body is sent as the empty text body
law exchange_body_empty:
  for method: String
  for l: Url.Loc
  for hs: List<&2, Http.Header>
  {Spec.wire.exchange.body(method, l, hs,
    Pair.fst(Body.Shape, Bytes.Bytes, Body.body.shape(Body.Empty{})))
    == Spec.wire.exchange(method, l, hs, "") : Spec.Exchange}

# LAW: an octet body's request text is built for its number of octets
law exchange_body_octets:
  for method: String
  for l: Url.Loc
  for hs: List<&2, Http.Header>
  for +n: U32
  for buf: Array<U32>
  {Spec.wire.exchange.body(method, l, hs,
    Pair.fst(Body.Shape, Bytes.Bytes,
      Body.body.shape(Body.Octets{Bytes.Bytes{n, buf}})))
    == Spec.wire.exchange.octets(method, l, hs, U32.to_nat(n))
    : Spec.Exchange}

# LAW: a URL that does not parse sends nothing and keeps its reason
law exchange_octets_bad:
  for method: String
  for why: String
  for hs: List<&2, Http.Header>
  for n: Nat
  {Spec.wire.exchange.octets(method, Url.Bad{why}, hs, n) == Spec.NoUrl{why}
    : Spec.Exchange}

# LAW: a URL that parses is sent to its host and port, over TLS exactly when
# its scheme is https, with the method it was given and the request text
# request.head.at writes for n octets
law exchange_octets_loc:
  for +method: String
  for +scheme: String
  for +host: String
  for +port: U32
  for path: String
  for hs: List<&2, Http.Header>
  for n: Nat
  {Spec.wire.exchange.octets(method, Url.Loc{scheme, host, port, path}, hs, n)
    == Spec.Exchange{String.eq(scheme, "https"), host, port, method,
      Http.request.head.at(method, String.eq(scheme, "https"), host, port,
        path, hs, n)} : Spec.Exchange}

# LAW (RFC 9112 §3): the request text ahead of n octets is the request line,
# the header fields for n octets, and the blank line, nothing after it
law request_head_at:
  for +method: String
  for secure: Bool
  for host: String
  for port: U32
  for +path: String
  for hs: List<&2, Http.Header>
  for n: Nat
  {Http.request.head.at(method, secure, host, port, path, hs, n)
    == method ++ " " ++ path ++ " HTTP/1.1\r\n"
      ++ Http.headers.lines(
        Http.request.fields.n(Http.authority(secure, host, port), hs, n))
      ++ "\r\n"
    : String}

# LAW (RFC 9110 §8.6): a text body's header fields are the fields for its
# UTF-8 octets
law fields_n:
  for host: String
  for +hs: List<&2, Http.Header>
  for +body: String
  {Http.request.fields(host, hs, body)
    == Http.request.fields.n(host, hs, Http.utf8.len(body))
    : List<&2, Http.Header>}

# LAW (RFC 9110 §8.6): whatever the caller gave, the Content-Length fields for
# n octets are exactly `Content-Length: n`, and none for none
law fields_clen_n:
  for +host: String
  for +hs: List<&2, Http.Header>
  for +n: Nat
  {Http.fields.of(Http.FClen{}, Http.request.fields.n(host, hs, n))
    == Http.clen.field(n, Nat.is_eq(n, 0n)) : List<&2, Http.Header>}

# LAW: what is sent ahead of the body's octets is the request text's octets
law payload_is:
  for req: String
  {Spec.wire.payload(req) == Spec.wire.payload.text(req, "") : String}

# LAW: an empty request text writes no octets ahead of what follows it
law payload_nil:
  for rest: String
  {Spec.wire.payload.text("", rest) == rest : String}

# LAW (RFC 3629 §3): every character of the request text is sent as its
# UTF-8 octets, in order, ahead of the rest
law payload_cons:
  for +cp: U32
  for t: String
  for rest: String
  {Spec.wire.payload.text(SCon{Chr{cp}, t}, rest)
    == Body.octets.chars(Pct.utf8(cp)) ++ Spec.wire.payload.text(t, rest)
    : String}

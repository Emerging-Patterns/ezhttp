# A field name is compared case-insensitively (RFC 9110 §5.1): it is Host,
# User-Agent, Accept, Connection or Content-Length exactly when its
# lower-case form is `host`, `user-agent`, `accept`, `connection` or
# `content-length`. For every header list and body, the request's header
# fields are, in order, its Host, User-Agent and Accept fields, `Connection:
# close`, the caller's other fields, then its Content-Length field. For each
# of Host, User-Agent and Accept, the request's fields of that name are
# exactly the caller's fields of that name, unchanged and in order, when the
# caller gave one or more (so exactly one, the caller's, when it gave one),
# and exactly the default (`Host: <authority>` as
# laws/RequestLineAndHost.bend writes it, `User-Agent: ezhttp`, `Accept:
# */*`) when it gave none. Connection and Content-Length are not
# overridable: the request's Connection fields are exactly `Connection:
# close`, and its Content-Length fields exactly `Content-Length: <octets of
# the body>` when the body is not empty and none when it is empty; a
# caller's field of either name is not sent. The caller's fields of every
# other name are sent unchanged and in order. A caller that names none of
# the five gets exactly the request ezhttp 0.12 wrote.
import Base
import ../src/http.bend as Http

# --- the request's header fields ---

# LAW (RFC 9110 §5.1): a field name whose lower-case form is `host` is Host
law field_host:
  for +name: String
  for e: {"host" == String.to_lower(name) : String}
  {Http.field.name(name) == Http.FHost{} : Http.Field}

# LAW (RFC 9110 §5.1): a field name whose lower-case form is `user-agent` is
# User-Agent
law field_agent:
  for +name: String
  for e: {"user-agent" == String.to_lower(name) : String}
  {Http.field.name(name) == Http.FAgent{} : Http.Field}

# LAW (RFC 9110 §5.1): a field name whose lower-case form is `accept` is
# Accept
law field_accept:
  for +name: String
  for e: {"accept" == String.to_lower(name) : String}
  {Http.field.name(name) == Http.FAccept{} : Http.Field}

# LAW (RFC 9110 §5.1): a field name whose lower-case form is `connection` is
# Connection
law field_conn:
  for +name: String
  for e: {"connection" == String.to_lower(name) : String}
  {Http.field.name(name) == Http.FConn{} : Http.Field}

# LAW (RFC 9110 §5.1): a field name whose lower-case form is
# `content-length` is Content-Length
law field_clen:
  for +name: String
  for e: {"content-length" == String.to_lower(name) : String}
  {Http.field.name(name) == Http.FClen{} : Http.Field}

# LAW (RFC 9110 §5.1): a field name whose lower-case form is none of the five
# is another field
law field_other:
  for +name: String
  for eh: {False{} == String.eq(String.to_lower(name), "host") : Bool}
  for ea: {False{} == String.eq(String.to_lower(name), "user-agent") : Bool}
  for ec: {False{} == String.eq(String.to_lower(name), "accept") : Bool}
  for en: {False{} == String.eq(String.to_lower(name), "connection") : Bool}
  for el: {False{} == String.eq(String.to_lower(name), "content-length")
    : Bool}
  {Http.field.name(name) == Http.FOther{} : Http.Field}

# LAW (RFC 9112 §3): the request is its request line, its header fields, a
# blank line and the body
law request_text:
  for +method: String
  for +host: String
  for +path: String
  for hs: List<&2, Http.Header>
  for +body: String
  {Http.request(method, host, path, hs, body)
    == method ++ " " ++ path ++ " HTTP/1.1\r\n"
      ++ Http.headers.lines(Http.request.fields(host, hs, body))
      ++ "\r\n"
      ++ body
    : String}

# LAW: a caller's Host fields replace the default: the request's Host fields
# are exactly the caller's, in order
law fields_host_caller:
  for +host: String
  for +hs: List<&2, Http.Header>
  for +body: String
  for +h: Http.Header
  for +t: List<&2, Http.Header>
  for +e: {Http.fields.of(Http.FHost{}, hs) == h <> t : List<&2, Http.Header>}
  {Http.fields.of(Http.FHost{}, Http.request.fields(host, hs, body))
    == h <> t : List<&2, Http.Header>}

# LAW (RFC 9110 §7.2): with no Host field from the caller, the request's Host
# fields are exactly the default one
law fields_host_dflt:
  for +host: String
  for +hs: List<&2, Http.Header>
  for +body: String
  for +e: {Http.fields.of(Http.FHost{}, hs) == [] : List<&2, Http.Header>}
  {Http.fields.of(Http.FHost{}, Http.request.fields(host, hs, body))
    == [Http.H{"Host", host}] : List<&2, Http.Header>}

# LAW: a caller's User-Agent fields replace the default: the request's
# User-Agent fields are exactly the caller's, in order
law fields_agent_caller:
  for +host: String
  for +hs: List<&2, Http.Header>
  for +body: String
  for +h: Http.Header
  for +t: List<&2, Http.Header>
  for +e: {Http.fields.of(Http.FAgent{}, hs) == h <> t : List<&2, Http.Header>}
  {Http.fields.of(Http.FAgent{}, Http.request.fields(host, hs, body))
    == h <> t : List<&2, Http.Header>}

# LAW: with no User-Agent field from the caller, the request's User-Agent
# fields are exactly `User-Agent: ezhttp`
law fields_agent_dflt:
  for +host: String
  for +hs: List<&2, Http.Header>
  for +body: String
  for +e: {Http.fields.of(Http.FAgent{}, hs) == [] : List<&2, Http.Header>}
  {Http.fields.of(Http.FAgent{}, Http.request.fields(host, hs, body))
    == [Http.H{"User-Agent", "ezhttp"}] : List<&2, Http.Header>}

# LAW: a caller's Accept fields replace the default: the request's Accept
# fields are exactly the caller's, in order
law fields_accept_caller:
  for +host: String
  for +hs: List<&2, Http.Header>
  for +body: String
  for +h: Http.Header
  for +t: List<&2, Http.Header>
  for +e: {Http.fields.of(Http.FAccept{}, hs) == h <> t
    : List<&2, Http.Header>}
  {Http.fields.of(Http.FAccept{}, Http.request.fields(host, hs, body))
    == h <> t : List<&2, Http.Header>}

# LAW: with no Accept field from the caller, the request's Accept fields are
# exactly `Accept: */*`
law fields_accept_dflt:
  for +host: String
  for +hs: List<&2, Http.Header>
  for +body: String
  for +e: {Http.fields.of(Http.FAccept{}, hs) == [] : List<&2, Http.Header>}
  {Http.fields.of(Http.FAccept{}, Http.request.fields(host, hs, body))
    == [Http.H{"Accept", "*/*"}] : List<&2, Http.Header>}

# LAW (RFC 9112 §9.6): whatever the caller gave, the request's Connection
# fields are exactly `Connection: close`
law fields_conn:
  for +host: String
  for +hs: List<&2, Http.Header>
  for +body: String
  {Http.fields.of(Http.FConn{}, Http.request.fields(host, hs, body))
    == [Http.H{"Connection", "close"}] : List<&2, Http.Header>}

# LAW (RFC 9110 §8.6): whatever the caller gave, the request's Content-Length
# fields are exactly the one computed from the body
law fields_clen:
  for +host: String
  for +hs: List<&2, Http.Header>
  for +body: String
  {Http.fields.of(Http.FClen{}, Http.request.fields(host, hs, body))
    == Http.clen.field(Http.utf8.len(body), Nat.is_eq(Http.utf8.len(body), 0n))
    : List<&2, Http.Header>}

# LAW: the caller's fields of every other name are sent unchanged and in
# order, and the request adds none of its own
law fields_other:
  for +host: String
  for +hs: List<&2, Http.Header>
  for +body: String
  {Http.fields.of(Http.FOther{}, Http.request.fields(host, hs, body))
    == Http.fields.of(Http.FOther{}, hs) : List<&2, Http.Header>}

# LAW (RFC 9110 §7.2, RFC 9112 §3, §9.6): a caller that names none of the
# five defaulted fields gets the request ezhttp has always written: Host,
# User-Agent, Accept, Connection: close, its own fields, Content-Length
law request_plain:
  for +method: String
  for +host: String
  for +path: String
  for +hs: List<&2, Http.Header>
  for +body: String
  for +eh: {Http.fields.of(Http.FHost{}, hs) == [] : List<&2, Http.Header>}
  for +ea: {Http.fields.of(Http.FAgent{}, hs) == [] : List<&2, Http.Header>}
  for +ec: {Http.fields.of(Http.FAccept{}, hs) == [] : List<&2, Http.Header>}
  for +eo: {Http.fields.of(Http.FOther{}, hs) == hs : List<&2, Http.Header>}
  {Http.request(method, host, path, hs, body)
    == method ++ " " ++ path ++ " HTTP/1.1\r\n"
      ++ "Host: " ++ host ++ "\r\n"
      ++ "User-Agent: ezhttp\r\n"
      ++ "Accept: */*\r\n"
      ++ "Connection: close\r\n"
      ++ Http.headers.lines(hs)
      ++ Http.clen.line(Http.utf8.len(body), Nat.is_eq(Http.utf8.len(body), 0n))
      ++ "\r\n"
      ++ body
    : String}

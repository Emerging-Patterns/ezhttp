# For every status, header fields and count `n`, the head of a reply whose
# body is `n` octets (`respond.head`) is `HTTP/1.1 <status> <reason>` CRLF
# (laws/ReasonPhrasesFollowRfc.bend), `Connection: close` CRLF, the header
# lines, `Content-Length: <n>` CRLF when `n` is not 0, and CRLF; a packed
# octets reply is that head and then its octets unchanged (trusted in
# src/server.bend), and a text reply is exactly the octets reply of its
# body's UTF-8 octets (`respond` is `respond.head` onto the body).
import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §4, §6.3): the head of a reply of n octets
law respond_head:
  for +status: U32
  for hs: List<&2, Http.Header>
  for +n: Nat
  {Http.respond.head(status, hs, n)
    == "HTTP/1.1 " ++ U32.show(status) ++ " " ++ Http.reason(status) ++ "\r\n"
      ++ "Connection: close\r\n"
      ++ Http.headers.lines(hs)
      ++ Http.clen.line(n, Nat.is_eq(n, 0n))
      ++ "\r\n" ++ "" : String}

# LAW: a text reply is the head of its UTF-8 octets onto the body
law respond_text_is:
  for +status: U32
  for hs: List<&2, Http.Header>
  for +body: String
  {Http.respond(status, hs, body)
    == Http.respond.head.onto(status, hs, Http.utf8.len(body), body) : String}

# LAW: the head written onto what follows it is the head, then that
law respond_head_onto:
  for +status: U32
  for hs: List<&2, Http.Header>
  for +n: Nat
  for rest: String
  {Http.respond.head.onto(status, hs, n, rest)
    == "HTTP/1.1 " ++ U32.show(status) ++ " " ++ Http.reason(status) ++ "\r\n"
      ++ "Connection: close\r\n"
      ++ Http.headers.lines(hs)
      ++ Http.clen.line(n, Nat.is_eq(n, 0n))
      ++ "\r\n" ++ rest : String}

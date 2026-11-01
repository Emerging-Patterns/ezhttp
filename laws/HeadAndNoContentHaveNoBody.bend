# For every reply, the server writes it with an empty body when the request
# method is exactly `HEAD` (RFC 9110 §9.3.2) or the status is 204 or 304
# (RFC 9110 §15.3.5, §15.4.5), and writes its status, headers and body
# unchanged otherwise.
import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §9.3.2): a reply to HEAD loses its body and keeps the rest
law shape_head:
  for status: U32
  for hs: List<&2, Http.Header>
  for body: String
  {Http.reply.for("HEAD", Http.Reply{status, hs, body})
    == Http.Reply{status, hs, ""} : Http.Reply}

# LAW: a reply to any method other than HEAD is left as it is
law shape_other:
  for method: String
  for e: {False{} == String.eq(method, "HEAD") : Bool}
  for reply: Http.Reply
  {Http.reply.for(method, reply) == reply : Http.Reply}

# LAW (RFC 9110 §15.3.5): a 204 is written with no body
law respond_204:
  for hs: List<&2, Http.Header>
  for body: String
  {Http.respond.of(Http.Reply{204, hs, body}) == Http.respond(204, hs, "")
    : String}

# LAW (RFC 9110 §15.4.5): a 304 is written with no body
law respond_304:
  for hs: List<&2, Http.Header>
  for body: String
  {Http.respond.of(Http.Reply{304, hs, body}) == Http.respond(304, hs, "")
    : String}

# LAW: any other status is written with its headers and body as they are
law respond_other:
  for +status: U32
  for e: {False{} == Http.status.nocontent(status) : Bool}
  for hs: List<&2, Http.Header>
  for body: String
  {Http.respond.of(Http.Reply{status, hs, body})
    == Http.respond(status, hs, body) : String}

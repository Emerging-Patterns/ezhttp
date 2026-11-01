# For every status, the reason-phrase the server writes after it is exactly
# the one RFC 9110 §15 names (RFC 6585 §4 for 429): 200 `OK`, 201 `Created`,
# 202 `Accepted`, 204 `No Content`, 301 `Moved Permanently`, 302 `Found`,
# 303 `See Other`, 304 `Not Modified`, 307 `Temporary Redirect`, 308
# `Permanent Redirect`, 400 `Bad Request`, 401 `Unauthorized`, 403
# `Forbidden`, 404 `Not Found`, 405 `Method Not Allowed`, 409 `Conflict`,
# 410 `Gone`, 413 `Content Too Large`, 415 `Unsupported Media Type`, 422
# `Unprocessable Content`, 429 `Too Many Requests`, 500 `Internal Server
# Error`, 501 `Not Implemented`, 502 `Bad Gateway`, 503 `Service
# Unavailable`, 504 `Gateway Timeout`; for every other status it is empty.
#
# also rests on: laws/PhraseTableLookup.bend
import Base
import ../src/http.bend as Http
import ../src/redirect.bend as Redirect

# --- RFC 9112 request and response writers ---

# LAW (RFC 9112 §4, §9.6): a response status-line is HTTP/1.1 plus the
# reason-phrase, and the connection closes
law respond_writes_reason_and_close:
  for +status: U32
  for hs: List<&2, Http.Header>
  for +body: String
  {Http.respond(status, hs, body)
    == "HTTP/1.1 " ++ U32.show(status) ++ " " ++ Http.reason(status) ++ "\r\n"
      ++ "Connection: close\r\n"
      ++ Http.headers.lines(hs)
      ++ Http.clen.line(Http.utf8.len(body), Nat.is_eq(Http.utf8.len(body), 0n))
      ++ "\r\n"
      ++ body
    : String}

# the reason-phrases this file opens with, as it words them
def phrases() -> List<&2, Http.Phrase>:
  [Http.P{200, "OK"}, Http.P{201, "Created"}, Http.P{202, "Accepted"},
    Http.P{204, "No Content"}, Http.P{301, "Moved Permanently"},
    Http.P{302, "Found"}, Http.P{303, "See Other"},
    Http.P{304, "Not Modified"}, Http.P{307, "Temporary Redirect"},
    Http.P{308, "Permanent Redirect"}, Http.P{400, "Bad Request"},
    Http.P{401, "Unauthorized"}, Http.P{403, "Forbidden"},
    Http.P{404, "Not Found"}, Http.P{405, "Method Not Allowed"},
    Http.P{409, "Conflict"}, Http.P{410, "Gone"},
    Http.P{413, "Content Too Large"}, Http.P{415, "Unsupported Media Type"},
    Http.P{422, "Unprocessable Content"}, Http.P{429, "Too Many Requests"},
    Http.P{500, "Internal Server Error"}, Http.P{501, "Not Implemented"},
    Http.P{502, "Bad Gateway"}, Http.P{503, "Service Unavailable"},
    Http.P{504, "Gateway Timeout"}]

# LAW: every status's reason-phrase is the one
# laws/ReasonPhrasesFollowRfc.bend lists for it, and empty for a status it
# does not list
law reason_phrases:
  for +code: U32
  {Http.reason(code) == Http.reason.in(phrases(), code) : String}

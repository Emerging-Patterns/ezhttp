# Differential check for SPEC.md HTTP-TRUST-9: packed.reply reads each
# response in the corpus off its packed octets exactly as Http.parse.to reads
# it as text, for GET and for HEAD. `ezhttp-bench parse-diff` prints one line
# a case, `ok` or `DIFF`; the flake check fails on any DIFF.
import Base
import bend-kit-bytes@0.3.2.0/bytes.bend as Bytes
import ../src/http.bend as Http
import ../src/packed.bend as Packed

# header fields on one line
def hs.show(hs: List<&2, Http.Header>) -> String:
  match hs:
    case []:
      ""
    case Http.H{n, v} <> t:
      n ++ "=" ++ v ++ ";" ++ hs.show(t)

# the text parse's reading on one line
def text.show(r: Http.Reply) -> String:
  match r:
    case Http.Torn{why}:
      "torn " ++ why
    case Http.Reply{st, hs, body}:
      U32.show(st) ++ " [" ++ hs.show(hs) ++ "] " ++ body

# the packed reader's reading on one line
def got.show(g: Packed.Got) -> String:
  match g:
    case Packed.Torn{why}:
      "torn " ++ why
    case Packed.Got{st, hs, reason, body}:
      U32.show(st) ++ " [" ++ hs.show(hs) ++ "] " ++ Bytes.to_string(body)

# a case read both ways, "ok" and the reading when they agree
def diff.one(+method: String, +raw: String) -> String:
  +a = text.show(Http.parse.to(method, raw))
  +b = got.show(Packed.packed.reply(method, Bytes.from_string(raw)))
  Bool.pick(String, String.eq(a, b), "ok   " ++ a, "DIFF text=" ++ a ++ " || packed=" ++ b)

# the corpus: sized, short, to the close, chunked (extensions, trailers, short
# and non-hex chunks), TE with CL, disagreeing CLs, interim heads, 204, 304,
# no status line, no blank line, an octet past 127
def diff.cases() -> List<&2, String>:
  ["HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\nhello",
   "HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\nhelloEXTRA",
   "HTTP/1.1 200 OK\r\nContent-Length: 9\r\n\r\nhello",
   "HTTP/1.1 200 OK\r\n\r\nto the close",
   "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n4\r\nwiki\r\n5\r\npedia\r\n0\r\n\r\n",
   "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n5;ext=1\r\nhello\r\n0\r\nX-T: 1\r\n\r\n",
   "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n4\r\nwi",
   "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n4\r\nwikiXX0\r\n\r\n",
   "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\nzz\r\nwiki\r\n0\r\n\r\n",
   "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n4\r\nwiki\r\n",
   "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n",
   "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\nContent-Length: 4\r\n\r\n4\r\nwiki\r\n0\r\n\r\n",
   "HTTP/1.1 200 OK\r\nContent-Length: 4\r\nContent-Length: 5\r\n\r\nwikis",
   "HTTP/1.1 200 OK\r\nContent-Length: 4\r\nContent-Length: 4\r\n\r\nwiki",
   "HTTP/1.1 200 OK\r\nContent-Length: abc\r\n\r\nwiki",
   "HTTP/1.1 100 Continue\r\n\r\nHTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nhi",
   "HTTP/1.1 100 Continue\r\n\r\n",
   "HTTP/1.1 103 Early\r\nLink: x\r\n\r\nHTTP/1.1 100 C\r\n\r\nHTTP/1.1 201 Created\r\n\r\nbody",
   "HTTP/1.1 204 No Content\r\nContent-Length: 5\r\n\r\nhello",
   "HTTP/1.1 304 Not Modified\r\n\r\n",
   "garbage\r\n\r\nbody",
   "HTTP/1.1 200 OK\r\nContent-Length: 5\r\n",
   "",
   "HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n",
   "HTTP/1.1 200 OK\r\nTransfer-Encoding: gzip, chunked\r\n\r\n1\r\n\u{FF}\r\n0\r\n\r\n",
   "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\nA\r\n0123456789\r\n0\r\n\r\n"]

# every case, read by this method
def diff.run(+method: String, cs: List<&2, String>) -> List<&2, String>:
  match cs:
    case []:
      []
    case c <> t:
      diff.one(method, c) <> diff.run(method, t)

# one line a case, for GET and then HEAD
def diff.report() -> String:
  String.join(diff.run("GET", diff.cases()), "\n") ++ "\n"
    ++ String.join(diff.run("HEAD", diff.cases()), "\n")

# For every status and header fields, a streamed reply's head
# (`respond.stream`) is the status line, `Connection: close` CRLF and the
# header lines, then `Transfer-Encoding: chunked` CRLF unless the status is
# 204 or 304 (RFC 9112 §6.1), then CRLF; each chunk of `n` octets is written
# (`chunk.frame`) as its size in 8 lowercase hexadecimal digits
# (`chunk.line`) and CRLF, its octets, and CRLF, and a chunk of 0 octets
# writes nothing, since it would end the body; the body ends with `0` CRLF
# CRLF (RFC 9112 §7.1).
import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §7.1): a streamed reply with a body is chunked
law stream_head:
  for +status: U32
  for e: {False{} == Http.status.nocontent(status) : Bool}
  for hs: List<&2, Http.Header>
  {Http.respond.stream(status, hs)
    == "HTTP/1.1 " ++ U32.show(status) ++ " " ++ Http.reason(status) ++ "\r\n"
      ++ "Connection: close\r\n" ++ Http.headers.lines(hs)
      ++ "Transfer-Encoding: chunked\r\n" ++ "\r\n" : String}

# LAW (RFC 9112 §6.1): a streamed 204 or 304 sends no Transfer-Encoding
law stream_head_bare:
  for +status: U32
  for e: {True{} == Http.status.nocontent(status) : Bool}
  for hs: List<&2, Http.Header>
  {Http.respond.stream(status, hs)
    == "HTTP/1.1 " ++ U32.show(status) ++ " " ++ Http.reason(status) ++ "\r\n"
      ++ "Connection: close\r\n" ++ Http.headers.lines(hs) ++ ""
      ++ "\r\n" : String}

# LAW: a chunk's size line is its 8 hex digits, high first, then CRLF
law chunk_line:
  for +n: U32
  {Http.chunk.line(n)
    == SCon{Http.hex.at(n, 28n), SCon{Http.hex.at(n, 24n),
      SCon{Http.hex.at(n, 20n), SCon{Http.hex.at(n, 16n),
      SCon{Http.hex.at(n, 12n), SCon{Http.hex.at(n, 8n),
      SCon{Http.hex.at(n, 4n), SCon{Http.hex.at(n, 0n), "\r\n"}}}}}}}}
    : String}

# LAW: a hex digit is the 4 bits at its shift, 0-9 then lowercase a-f
law hex_at:
  for +n: U32
  for k: Nat
  {Http.hex.at(n, k) == Http.hex.nib(U32.and(U32.shrn(n, k), 15)) : Char}

# LAW: a value below 10 is its decimal digit, any other `a` onwards
law hex_nib:
  for +v: U32
  {Http.hex.nib(v) == Char.from_u32(Bool.pick(U32, U32.is_lt(v, 10),
    U32.add(v, 48), U32.add(v, 87))) : Char}

# LAW: an empty chunk is not written
law chunk_empty:
  for +n: U32
  for e: {True{} == U32.is_eq(n, 0) : Bool}
  {Http.chunk.frame(n) == Http.NoChunk{} : Http.Chunk}

# LAW: any other chunk is written after its size line
law chunk_some:
  for +n: U32
  for e: {False{} == U32.is_eq(n, 0) : Bool}
  {Http.chunk.frame(n) == Http.Chunk{Http.chunk.line(n)} : Http.Chunk}

# LAW (RFC 9112 §7.1): the body ends with the last chunk and no trailer
law chunk_end:
  for s: String
  for e: {"" == s : String}
  {Http.chunk.end() ++ s == "0\r\n\r\n" : String}

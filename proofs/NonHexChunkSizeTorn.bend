# proofs of laws/NonHexChunkSizeTorn.bend
import Base
import ../src/http.bend as Http
import ../laws/NonHexChunkSizeTorn.bend as Laws

def Laws.chunked_non_hex(st, hs, body, f, before, after, el, e, eh):
  %el : {Http.parse.chunked(st, hs, body,
    Http.chunks.scan(_, Http.divide(body, "\r\n")))
    == Http.Torn{"chunk size is not hexadecimal"} : Http.Reply}
  %e : {Http.parse.chunked(st, hs, body, Http.chunks.scan(1n+f, _))
    == Http.Torn{"chunk size is not hexadecimal"} : Http.Reply}
  %eh : {Http.parse.chunked(st, hs, body,
    Http.chunks.scan.step(Http.chunks.next.hex(before, after, _),
      cut => Http.chunks.scan(f, cut)))
    == Http.Torn{"chunk size is not hexadecimal"} : Http.Reply}
  {==}

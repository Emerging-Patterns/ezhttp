# For every status, header fields and chunked body whose chunk sizes are
# all hexadecimal and reach the last chunk (`chunks.scan` finds nothing
# wrong), the response's body is the chunks joined (`dechunk`, RFC 9112
# §7.1); what the joined chunks are is laws/ChunkDataUnchanged.bend.
import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §7.1): a well-framed chunked body is its chunks joined
law chunked_joins:
  for st: U32
  for hs: List<&2, Http.Header>
  for +body: String
  for e: {None{} == Http.chunks.scan(String.length(body), Http.divide(body, "\r\n"))
    : Maybe<&2, String>}
  {Http.parse.chunks(st, hs, body) == Http.Reply{st, hs, Http.dechunk(body)}
    : Http.Reply}

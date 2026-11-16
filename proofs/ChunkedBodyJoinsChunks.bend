# proofs of laws/ChunkedBodyJoinsChunks.bend
import Base
import ../src/http.bend as Http
import ../laws/ChunkedBodyJoinsChunks.bend as Laws

def Laws.chunked_joins(st, hs, body, e):
  %e : {Http.parse.chunked(st, hs, body, _) == Http.Reply{st, hs, Http.dechunk(body)}
    : Http.Reply}
  {==}

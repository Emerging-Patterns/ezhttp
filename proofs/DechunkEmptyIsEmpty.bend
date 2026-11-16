# proofs of laws/DechunkEmptyIsEmpty.bend
import Base
import ../src/http.bend as Http
import ../laws/DechunkEmptyIsEmpty.bend as Laws

# the decoder writes nothing when no chunk-size line is left
law dk.no_cut:
  for f: Nat
  {Http.chunks(f, Http.NoCut{}) == "" : String}

def dk.no_cut(f):
  match f:
    case 0n:
      {==}
    case 1n+p:
      {==}

def Laws.dechunk_no_crlf(s, e):
  %e : {Http.chunks(String.length(s), _) == "" : String}
  dk.no_cut(String.length(s))

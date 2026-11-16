# proofs of laws/ChunksStopWithoutFuel.bend
import Base
import ../laws/ChunksStopWithoutFuel.bend as Laws

def Laws.chunks_no_fuel(_c):
  {==}

def Laws.chunks_no_cut(f):
  match f:
    case 0n:
      {==}
    case 1n+p:
      {==}

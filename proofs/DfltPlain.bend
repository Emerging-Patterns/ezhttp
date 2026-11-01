# proofs of laws/DfltPlain.bend
import Base
import ../laws/DfltPlain.bend as Laws

def Laws.dflt_plain(_scheme, e):
  %e : {Bool.pick(U32, _, 443, 80) == 80 : U32}
  {==}

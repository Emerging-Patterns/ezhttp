# proofs of laws/OtherSchemesDefaultTo80.bend
import Base
import ../laws/OtherSchemesDefaultTo80.bend as Laws

def Laws.dflt_plain(_scheme, e):
  %e : {Bool.pick(U32, _, 443, 80) == 80 : U32}
  {==}

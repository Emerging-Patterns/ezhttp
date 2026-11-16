# proofs of laws/HttpsDefaultsTo443.bend
import Base
import ../laws/HttpsDefaultsTo443.bend as Laws

def Laws.dflt_https(_scheme, e):
  %e : {Bool.pick(U32, _, 443, 80) == 443 : U32}
  {==}

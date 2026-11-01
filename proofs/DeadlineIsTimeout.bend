# proofs of laws/DeadlineIsTimeout.bend
import Base
import ../src/wirespec.bend as Spec
import ../laws/DeadlineIsTimeout.bend as Laws

# --- the client's deadline and failures ---

def Laws.ms_none(_m, e):
  %e : {Spec.wire.ms.of(_) == 60000 : U32}
  {==}

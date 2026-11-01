# proofs of laws/TimeoutZeroIsOneMs.bend
import Base
import ../src/wirespec.bend as Spec
import ../laws/TimeoutZeroIsOneMs.bend as Laws

def Laws.ms_given(ms, e):
  %e : {Spec.wire.ms.pick(ms, _) == ms : U32}
  {==}

def Laws.ms_zero(ms, e):
  %e : {Spec.wire.ms.pick(ms, _) == 1 : U32}
  {==}

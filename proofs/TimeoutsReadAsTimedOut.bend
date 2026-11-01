# proofs of laws/TimeoutsReadAsTimedOut.bend
import Base
import ../src/wirespec.bend as Spec
import ../laws/TimeoutsReadAsTimedOut.bend as Laws
import ./lemmas/BaseEqualities.bend as M1

# --- the client's timeout ---

def Laws.why_late(_why):
  {==}

def Laws.why_other(_n, e, why):
  %e : {Spec.wire.why.of(why, _) == why : String}
  {==}

def Laws.why_none(_why):
  {==}

def Laws.why_late_timed_out(why):
  M1.eq.starts_append("timed out: ", why)

# For every reason `why`, a failed exchange with wire status 28 (ran out of
# time) is reported as `Err` with reason exactly `timed out: <why>`, which
# `http.timed_out` recognizes; a failed exchange with any other status, or
# none, is reported with `why` unchanged.
import Base
import ../src/wirespec.bend as Spec

# --- what a failed socket call is reported as ---

# LAW: a failed exchange with status 28 is reported as `timed out: <why>`
law why_late:
  for why: String
  {Spec.wire.why(Some{28}, why) == "timed out: " ++ why : String}

# LAW: a failed exchange with any other status keeps its reason unchanged
law why_other:
  for +n: U32
  for e: {False{} == U32.is_eq(n, 28) : Bool}
  for why: String
  {Spec.wire.why(Some{n}, why) == why : String}

# LAW: a failed exchange with no status keeps its reason unchanged
law why_none:
  for why: String
  {Spec.wire.why(None{}, why) == why : String}

# LAW: the reason reported for status 28 is one timed_out recognizes
law why_late_timed_out:
  for why: String
  {Spec.wire.timed_out(Spec.wire.why(Some{28}, why)) == True{} : Bool}

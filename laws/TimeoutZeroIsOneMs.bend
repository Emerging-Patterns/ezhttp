# For every timeout `ms` of 1 or more, the deadline is exactly `ms`; for a
# timeout of 0 it is 1 ms, since bend-kit-wire reads a deadline of 0 as
# none.
import Base
import ../src/wirespec.bend as Spec

# LAW: a timeout of 1 ms or more is the deadline every call gets, unchanged
law ms_given:
  for +ms: U32
  for e: {False{} == U32.is_eq(ms, 0) : Bool}
  {Spec.wire.ms.of(Some{ms}) == ms : U32}

# LAW: a timeout of 0 is a deadline of 1 ms (bend-kit-wire reads 0 as none)
law ms_zero:
  for +ms: U32
  for e: {True{} == U32.is_eq(ms, 0) : Bool}
  {Spec.wire.ms.of(Some{ms}) == 1 : U32}

import Base
import ../src/wirespec.bend as Spec

# LAW: the pieces put together in one pass are the text they stand for (the
# server puts a request's pieces together with it)
law join_joined:
  for +ps: List<&2, String>
  {Spec.wire.join(ps) == Spec.wire.joined(ps) : String}

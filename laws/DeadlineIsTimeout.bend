# The deadline an exchange gives bend-kit-wire for its connect, TLS
# handshake, sends and receives (`wire.ms.of`) is, for an exchange made with
# a timeout (`http.get_opts`, `http.request_opts`, `http.post_opts`,
# `http.put_opts`, `http.delete_opts`, `http.send.timed`), the timeout as
# laws/TimeoutZeroIsOneMs.bend gives it, and for every other exchange
# exactly 60000 ms.
#
# also rests on: laws/TimeoutZeroIsOneMs.bend
import Base
import ../src/wirespec.bend as Spec

# --- the client's deadline ---

# LAW: an exchange made with no timeout gives every call 60000 ms
law ms_none:
  for m: Maybe<&2, U32>
  for e: {None{} == m : Maybe<&2, U32>}
  {Spec.wire.ms.of(m) == 60000 : U32}

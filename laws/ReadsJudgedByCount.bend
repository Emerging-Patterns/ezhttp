# The client keeps the octets it has received packed (trusted in
# src/client.bend) and carries from one read to the next only the state
# `Http.hear` (laws/ReadStateMatchesWholeText.bend), starting from
# `wire.got(method)`, the state for no text. For every state `h`: a read of
# no octets (the connection closed) answers `Heard` (`wire.read.count(h,
# 0)`). For every state `h` and read text `b` that is not empty, when the
# state can be advanced by `b`'s count of octets alone (`Http.hear.counts`:
# the response is already whole, its body is framed by the close or by
# Content-Length, or a chunk's data still owes at least that many octets),
# `wire.read.count` answers exactly what `wire.read.next` answers for `b`
# itself, since advancing the state by the count (`Http.hear.more.n`) is
# exactly advancing it by `b` (`Http.hear.more`); walking `n` octets off a
# text of at most `n` octets leaves `n` minus its length still owed. For
# every method, text `a` received so far and read text `t` that is not
# empty, `wire.read.next` from the state for `a` answers `Heard` when `a ++
# t` is complete (laws/ResponseCompleteByFraming.bend), and otherwise reads
# again with the state for `a ++ t`.
import Base
import ../src/http.bend as Http
import ../src/wirespec.bend as Spec

# --- reading until the response is whole ---

# LAW: a read of no octets finds the connection closed, and the answer is
# everything received
law read_closed:
  for h: Http.Hear
  {Spec.wire.read.count(h, 0n) == Some{Spec.Heard{}} : Maybe<&2, Spec.Read>}

# LAW: a read whose count alone advances the state is judged by its count
# exactly as by its text
law read_count:
  for +h: Http.Hear
  for +b: String
  for e1: {False{} == String.is_empty(b) : Bool}
  for e2: {True{} == Http.hear.counts(h, String.length(b)) : Bool}
  {Spec.wire.read.count(h, String.length(b))
    == Some{Spec.wire.read.next(h, b)} : Maybe<&2, Spec.Read>}

# LAW: a state the count alone advances is advanced by a text's count
# exactly as by the text
law hear_count:
  for +h: Http.Hear
  for +b: String
  for e: {True{} == Http.hear.counts(h, String.length(b)) : Bool}
  {Http.hear.more.n(h, String.length(b)) == Http.hear.more(h, b) : Http.Hear}

# LAW: walking n octets off a text of at most n octets leaves n less its
# length owed
law skip_short:
  for +b: String
  for +n: Nat
  for e: {False{} == Nat.is_lt(n, String.length(b)) : Bool}
  {Http.octs.skip(b, n) == Http.Short{Nat.sub(n, String.length(b))}
    : Http.Skip}

# LAW: a read whose text completes the response is heard
law read_whole:
  for +method: String
  for +a: String
  for +text: String
  for e1: {False{} == String.is_empty(text) : Bool}
  for e2: {True{} == Http.whole(method, a ++ text) : Bool}
  {Spec.wire.read.next(Http.hear.of(method, a), text) == Spec.Heard{}
    : Spec.Read}

# LAW: a read whose text does not complete the response reads again, in the
# state for what has been received with it
law read_more:
  for +method: String
  for +a: String
  for +text: String
  for e1: {False{} == String.is_empty(text) : Bool}
  for e2: {False{} == Http.whole(method, a ++ text) : Bool}
  {Spec.wire.read.next(Http.hear.of(method, a), text)
    == Spec.Again{Http.hear.of(method, a ++ text)} : Spec.Read}

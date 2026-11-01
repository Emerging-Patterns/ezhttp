# For every request method and texts `a` and `b`, the state the client keeps
# between reads for `a` (`Http.hear.of(method, a)`), advanced by `b`
# (`Http.hear.more`), is exactly the state for `a ++ b`; and for every text
# the state says the response is complete (`Http.hear.done`) exactly when
# laws/ResponseCompleteByFraming.bend says that text is (`Http.whole`), so
# judging a response read by read decides exactly what judging all the text
# received after every read decides. Inside it, a chunked body's walk
# (`Http.walk`) from a chunk header with some fuel has ended exactly when
# `chunks.ended` says it has, and the walk over a text and more text is the
# walk over the text, advanced by the more.
import Base
import ../src/http.bend as Http

# --- judging a response read by read ---

# LAW: the state for a text says the response is complete exactly when the
# whole-text check (laws/ResponseCompleteByFraming.bend) says that text is
law hear_done:
  for +method: String
  for +raw: String
  {Http.hear.done(Http.hear.of(method, raw)) == Http.whole(method, raw)
    : Bool}

# LAW: the state for a text, advanced by more text, is the state for the two
# together
law hear_more:
  for +method: String
  for +a: String
  for +b: String
  {Http.hear.more(Http.hear.of(method, a), b) == Http.hear.of(method, a ++ b)
    : Http.Hear}

# LAW (RFC 9112 §7.1): a chunked body's walk from a chunk header has ended
# exactly when chunks.ended says, with the same fuel
law walk_done:
  for f: Nat
  for +rest: String
  {Http.walk.done(Http.walk(f, rest))
    == Http.chunks.ended(f, Http.divide(rest, "\r\n")) : Bool}

# LAW: the walk over a text and more text, with fuel for both, is the walk
# over the text advanced by the more
law walk_more:
  for f: Nat
  for +rest: String
  for +b: String
  {Http.walk(Nat.add(f, String.length(b)), rest ++ b)
    == Http.walk.more(Http.walk(f, rest), String.length(b), b) : Http.Walk}

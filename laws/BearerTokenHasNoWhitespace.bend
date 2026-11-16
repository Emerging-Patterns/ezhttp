# For every string, a bearer token (`token.ok`, RFC 6750 §2.1) is rejected
# when a whitespace character (space, tab, newline, CR, VT, FF) appears
# anywhere in it, and a leading non-whitespace character leaves the verdict
# to the rest; so a token is accepted exactly when it has no whitespace
# (`abc` is accepted; `a b`, `a\tb` and `a\nb` are rejected).
import Base
import ../src/http.bend as Http

# --- RFC 6750 / 7617 / 4648 credentials ---

# LAW (RFC 6750 §2.1): a whitespace character anywhere rejects the token
law token_ok_space:
  for a: String
  for +c: Char
  for +b: String
  for +e: {Char.is_space(c) == True{} : Bool}
  {Http.token.ok(a ++ SCon{c, b}) == False{} : Bool}

# LAW (RFC 6750 §2.1): a non-whitespace character leaves the rest to decide
law token_ok_plain:
  for c: Char
  for t: String
  for e: {Char.is_space(c) == False{} : Bool}
  {Http.token.ok(SCon{c, t}) == Http.token.ok(t) : Bool}

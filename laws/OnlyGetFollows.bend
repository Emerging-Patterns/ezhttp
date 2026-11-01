# For every flag `follow`, a GET follows redirects exactly when `follow` is
# set; for every other method (method names are case-sensitive, RFC 9110
# §9.1) it never does, whatever `follow` says.
import Base
import ../src/redirect.bend as Redirect

# --- which requests follow redirects ---

# LAW: a GET follows redirects exactly when it is asked to
law follows_get:
  for follow: Bool
  {Redirect.redirect.follows("GET", follow) == follow : Bool}

# LAW (RFC 9110 §9.1): every other method never follows redirects
law follows_other:
  for +method: String
  for e: {False{} == String.eq(method, "GET") : Bool}
  for follow: Bool
  {Redirect.redirect.follows(method, follow) == False{} : Bool}

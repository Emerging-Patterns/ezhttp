# For every method token, the server's client treats it as safe exactly when
# it is `GET`, `HEAD` or `OPTIONS` (RFC 9110 §9.2.1) and as idempotent
# exactly when it is safe, `PUT` or `DELETE` (RFC 9110 §9.2.2), compared
# case-sensitively (RFC 9110 §9.1, laws/MethodTokensAreCaseSensitive.bend):
# `get` is not safe, POST and PATCH are neither. Every safe method is
# idempotent.
import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §9.2.1): GET, HEAD and OPTIONS are the safe methods
law method_safe_is:
  for +method: String
  {Http.method.safe(method)
    == Bool.or(String.eq(method, "GET"),
      Bool.or(String.eq(method, "HEAD"), String.eq(method, "OPTIONS")))
    : Bool}

# LAW (RFC 9110 §9.2.2): the idempotent methods are the safe ones, PUT and
# DELETE
law method_idempotent_is:
  for +method: String
  {Http.method.idempotent(method)
    == Bool.or(Http.method.safe(method),
      Bool.or(String.eq(method, "PUT"), String.eq(method, "DELETE")))
    : Bool}

# LAW (RFC 9110 §9.2.2): every safe method is idempotent
law method_safe_idempotent:
  for +method: String
  for e: {Http.method.safe(method) == True{} : Bool}
  {Http.method.idempotent(method) == True{} : Bool}

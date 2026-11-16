# For every user and password, Basic credentials (`auth.basic`) are the
# Authorization field `Basic ` and the Base64 of `user:password`
# (laws/Base64EncodesByQuantum.bend); `user`/`pass` as
# `Basic dXNlcjpwYXNz` is an instance.
import Base
import ../src/http.bend as Http
import ../src/auth.bend as Auth
import ../src/b64.bend as B64

# LAW (RFC 7617 §2): Basic credentials are Base64 of user:password
law basic_user_pass:
  for user: String
  for password: String
  {Auth.auth.basic(user, password)
    == Http.H{"Authorization", "Basic " ++ B64.b64.encode(user ++ ":" ++ password)}
    : Http.Header}

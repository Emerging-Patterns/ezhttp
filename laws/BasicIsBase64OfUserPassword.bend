import Base
import ../src/http.bend as Http
import ../src/auth.bend as Auth

# LAW (RFC 7617 §2): Basic credentials are Base64 of user:password
law basic_user_pass:
  {Auth.auth.basic("user", "pass")
    == Http.H{"Authorization", "Basic dXNlcjpwYXNz"} : Http.Header}

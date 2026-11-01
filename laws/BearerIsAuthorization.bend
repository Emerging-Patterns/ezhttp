import Base
import ../src/http.bend as Http
import ../src/auth.bend as Auth

# --- main API surface (named so bolt laws stay clean) ---

# LAW: bearer builds Authorization: Bearer …
law bearer_is_authorization:
  for token: String
  {Auth.auth.bearer(token) == Http.H{"Authorization", "Bearer " ++ token}
    : Http.Header}

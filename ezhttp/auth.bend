# ezhttp/auth: Authorization header values, pure. Kept apart from client.bend
# (which reaches the wire effect) so the proof gate can import it.
import Base
import ./http.bend as Http
import ./b64.bend as B64

# Authorization: Bearer … (RFC 6750)
def auth.bearer(token: String) -> Http.Header:
  Http.H{"Authorization", "Bearer " ++ token}

# Authorization: Basic … (RFC 7617, credentials are RFC 4648 Base64)
def auth.basic(user: String, password: String) -> Http.Header:
  Http.H{"Authorization", "Basic " ++ B64.b64.encode(user ++ ":" ++ password)}

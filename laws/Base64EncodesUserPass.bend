import Base
import ../src/b64.bend as B64

# LAW (RFC 4648 §10 / RFC 7617 §2): user:pass is the Basic credential alphabet
law b64_user_pass:
  {B64.b64.encode("user:pass") == "dXNlcjpwYXNz" : String}

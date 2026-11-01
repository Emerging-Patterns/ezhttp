import Base
import ../src/b64.bend as B64

# LAW (RFC 4648 §10): `f` encodes to `Zg==`
law b64_f:
  {B64.b64.encode("f") == "Zg==" : String}

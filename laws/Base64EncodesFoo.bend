import Base
import ../src/b64.bend as B64

# LAW (RFC 4648 §10): `foo` encodes to `Zm9v`
law b64_foo:
  {B64.b64.encode("foo") == "Zm9v" : String}

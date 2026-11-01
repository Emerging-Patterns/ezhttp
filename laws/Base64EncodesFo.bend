import Base
import ../src/b64.bend as B64

# LAW (RFC 4648 §10): `fo` encodes to `Zm8=`
law b64_fo:
  {B64.b64.encode("fo") == "Zm8=" : String}

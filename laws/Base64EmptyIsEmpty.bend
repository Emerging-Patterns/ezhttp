import Base
import ../src/b64.bend as B64

# LAW (RFC 4648 §4): the empty string encodes to empty
law b64_empty:
  {B64.b64.encode("") == "" : String}

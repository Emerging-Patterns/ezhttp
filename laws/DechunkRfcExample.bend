import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §7.1): the chunked example wiki + pedia is wikipedia
law dechunk_wiki:
  {Http.dechunk("4\r\nwiki\r\n5\r\npedia\r\n0\r\n\r\n") == "wikipedia" : String}

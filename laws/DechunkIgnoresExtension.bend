import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §7.1): a chunk-ext after `;` does not change the decoded body
law dechunk_ignores_extension:
  {Http.dechunk("5;ext=1\r\nhello\r\n0\r\n\r\n") == "hello" : String}

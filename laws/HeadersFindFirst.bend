import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §5.2): the first field of a repeated name is the one found
law headers_find_first:
  {Http.headers.find([Http.H{"Host", "a"}, Http.H{"Host", "b"}], "host")
    == "a" : String}

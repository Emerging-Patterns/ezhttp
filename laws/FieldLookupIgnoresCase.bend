import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §5.1): field lookup folds the name and keeps the value
law headers_find_ignores_case:
  {Http.headers.find([Http.H{"hOsT", "Ex.COM"}], "host") == "Ex.COM" : String}

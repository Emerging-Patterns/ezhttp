import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §5.1): field names are compared case-insensitively
law head_hit_ignores_case:
  for +h: String
  for +name: String
  {Http.head.hit(h, name)
    == String.starts_with(String.to_lower(h), name ++ ":") : Bool}

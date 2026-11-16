import Base
import ../src/http.bend as Http
import ../src/cors.bend as Cors

# LAW (RFC 9110 §5.1): a requested header name matches the allow-list the same
# way as any name with the same lowercase spelling
law cors_preflight_header_case:
  for +a: String
  for +b: String
  for +xs: List<&2, String>
  for e: {String.to_lower(a) == String.to_lower(b) : String}
  {Cors.cors.hit_ci(a, xs) == Cors.cors.hit_ci(b, xs) : Bool}

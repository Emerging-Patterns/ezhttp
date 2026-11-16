# proofs of laws/CorsPreflightHeadersIgnoreCase.bend
import Base
import ../src/http.bend as Http
import ../src/cors.bend as Cors
import ../laws/CorsPreflightHeadersIgnoreCase.bend as Laws

def Laws.cors_preflight_header_case(a, _b, xs, e):
  %e : {Cors.cors.hit(String.to_lower(a), Cors.cors.lower(xs))
    == Cors.cors.hit(_, Cors.cors.lower(xs)) : Bool}
  {==}

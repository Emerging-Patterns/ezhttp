# For every request path with fewer than two `/` (so `/a` and `/`), the
# default-path of a cookie it set is `/` (RFC 6265 §5.1.4 steps 2-3).
import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.1.4 steps 2-3): fewer than two slashes, default-path /
law cookie_default_path_root:
  for +p: String
  for e: {True{} == Nat.is_lt(Cookie.cookie.slashes(p), 2n) : Bool}
  {Cookie.cookie.default_path(p) == "/" : String}

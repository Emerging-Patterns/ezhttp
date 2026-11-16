# For every request path with two `/` or more, the default-path of a cookie
# it set is its characters up to, not including, the right-most `/`, so
# `/a/b` gives `/a` and `/foo/bar/` gives `/foo/bar` (RFC 6265 §5.1.4 step
# 4); `cookie.before` is that prefix: the reversed path with everything
# through its first `/` dropped, reversed back.
import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.1.4 step 4): the path up to its right-most slash
law cookie_default_path_dir:
  for +p: String
  for e: {False{} == Nat.is_lt(Cookie.cookie.slashes(p), 2n) : Bool}
  {Cookie.cookie.default_path(p) == Cookie.cookie.before(p) : String}

# LAW: the prefix before the right-most slash
law cookie_before:
  for p: String
  {Cookie.cookie.before(p)
    == String.reverse(Cookie.cookie.skip(String.reverse(p))) : String}

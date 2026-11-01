# Dot segments are removed as RFC 3986 §5.2.4 removes them, segment by
# segment from the left: a `.` segment is dropped, a `..` segment drops the
# last segment kept so far (none when none is kept), every other segment is
# kept, and a path that ends in `.` or `..` keeps its trailing `/`.
import Base
import ../src/redirect.bend as Redirect

# LAW (RFC 3986 §5.2.4): a path is `/`, then its segments with dot segments
# removed, joined by `/`
law clean_path:
  for ss: List<&2, String>
  {Redirect.redirect.clean(ss)
    == "/" ++ String.join(Redirect.redirect.dots(ss, []), "/") : String}

# LAW: once every segment is read, the kept ones are the path, in order
law dots_nil:
  for out: List<&2, String>
  {Redirect.redirect.dots([], out) == List.reverse(&2, String, out)
    : List<&2, String>}

# LAW (RFC 3986 §5.2.4 B, D): a `.` segment is dropped
law dots_dot:
  for +s: String
  for +t: List<&2, String>
  for out: List<&2, String>
  for e: {True{} == String.eq(s, ".") : Bool}
  {Redirect.redirect.dots(s <> t, out)
    == Redirect.redirect.dots(t,
      Redirect.redirect.dots.end(List.is_empty(&2, String, t), out))
    : List<&2, String>}

# LAW (RFC 3986 §5.2.4 C, D): a `..` segment drops the last segment kept
law dots_up:
  for +s: String
  for +t: List<&2, String>
  for out: List<&2, String>
  for e1: {False{} == String.eq(s, ".") : Bool}
  for e2: {True{} == String.eq(s, "..") : Bool}
  {Redirect.redirect.dots(s <> t, out)
    == Redirect.redirect.dots(t,
      Redirect.redirect.dots.end(List.is_empty(&2, String, t),
        Redirect.redirect.pop(out))) : List<&2, String>}

# LAW (RFC 3986 §5.2.4 E): every other segment is kept
law dots_seg:
  for +s: String
  for +t: List<&2, String>
  for out: List<&2, String>
  for e1: {False{} == String.eq(s, ".") : Bool}
  for e2: {False{} == String.eq(s, "..") : Bool}
  {Redirect.redirect.dots(s <> t, out) == Redirect.redirect.dots(t, s <> out)
    : List<&2, String>}

# LAW (RFC 3986 §5.2.4 B, C): a path that ends in `.` or `..` keeps its
# trailing `/`
law dots_last:
  for out: List<&2, String>
  {Redirect.redirect.dots.end(True{}, out) == "" <> out : List<&2, String>}

# LAW: a `.` or `..` before other segments adds nothing
law dots_inner:
  for out: List<&2, String>
  {Redirect.redirect.dots.end(False{}, out) == out : List<&2, String>}

# LAW (RFC 3986 §5.2.4 C): `..` with nothing kept drops nothing
law pop_nil:
  for out: List<&2, String>
  for e: {True{} == List.is_empty(&2, String, out) : Bool}
  {Redirect.redirect.pop(out) == [] : List<&2, String>}

# LAW (RFC 3986 §5.2.4 C): `..` drops the last segment kept
law pop_cons:
  for s: String
  for t: List<&2, String>
  {Redirect.redirect.pop(s <> t) == t : List<&2, String>}

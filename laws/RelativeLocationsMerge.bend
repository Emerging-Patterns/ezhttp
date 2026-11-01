# Against a current URL that parses into scheme, host, port and path, a
# Location that starts `?` is the scheme, `://`, host, `:`, port, the
# current path without its query, then the Location; any other relative
# Location (a relative-path reference, such as `web/`) is the scheme, `://`,
# host, `:`, port, then the merge of the current path (without its query)
# and the Location's path (RFC 3986 §5.2.3: the current path's segments but
# its last, then the Location's) with dot segments removed, then the
# Location's query unchanged, its fragment dropped.
#
# also rests on: laws/LocationResolvedBySort.bend,
# laws/LocationSplitsAtQuery.bend
import Base
import ../src/url.bend as Url
import ../src/redirect.bend as Redirect

# LAW (RFC 3986 §5.2.2): a query keeps the origin and the current path
law against_query:
  for scheme: String
  for host: String
  for port: U32
  for path: String
  for +loc: String
  {Redirect.redirect.against(scheme, host, port, path, loc, Redirect.Query{})
    == Some{scheme ++ "://" ++ host ++ ":" ++ U32.show(port)
      ++ Redirect.redirect.base(path) ++ loc} : Maybe<&2, String>}

# LAW (RFC 3986 §5.2.2): a relative path keeps the origin and is merged with
# the current path
law against_rel:
  for scheme: String
  for host: String
  for port: U32
  for path: String
  for +loc: String
  {Redirect.redirect.against(scheme, host, port, path, loc, Redirect.Rel{})
    == Some{scheme ++ "://" ++ host ++ ":" ++ U32.show(port)
      ++ Redirect.redirect.rel.of(Redirect.redirect.base(path),
        Redirect.redirect.split(loc))} : Maybe<&2, String>}

# LAW (RFC 3986 §4.2): any other Location that starts `?` is a query
law sort_query:
  for +loc: String
  for e1: {False{} == String.starts_with(loc, "//") : Bool}
  for e2: {False{} == String.starts_with(loc, "/") : Bool}
  for e3: {False{} == Redirect.redirect.stays(loc) : Bool}
  for e4: {True{} == String.starts_with(loc, "?") : Bool}
  {Redirect.redirect.sort(loc) == Redirect.Query{} : Redirect.Sort}

# LAW (RFC 3986 §4.2): and every other one is a relative path
law sort_rel:
  for +loc: String
  for e1: {False{} == String.starts_with(loc, "//") : Bool}
  for e2: {False{} == String.starts_with(loc, "/") : Bool}
  for e3: {False{} == Redirect.redirect.stays(loc) : Bool}
  for e4: {False{} == String.starts_with(loc, "?") : Bool}
  {Redirect.redirect.sort(loc) == Redirect.Rel{} : Redirect.Sort}

# LAW (RFC 3986 §5.2.3): a relative path follows every segment of the current
# path but its last, then dot segments are removed, then its query
law rel_of:
  for base: String
  for path: String
  for query: String
  {Redirect.redirect.rel.of(base, Redirect.Ref{path, query})
    == Redirect.redirect.clean(List.tail(&2, String,
      List.append(&2, String, Redirect.redirect.init(String.split(base, '/')),
        String.split(path, '/')))) ++ query : String}

# LAW: the current path, for merging, is the part before its `?`
law base_path:
  for path: String
  {Redirect.redirect.base(path) == Url.query.hier(String.split(path, '?'))
    : String}

# LAW: the first piece of a split, empty when there is none
law hier_first:
  for h: String
  for t: List<&2, String>
  {Url.query.hier(h <> t) == h : String}

# LAW: no segments have no segments but the last
law init_nil:
  for ss: List<&2, String>
  for e: {True{} == List.is_empty(&2, String, ss) : Bool}
  {Redirect.redirect.init(ss) == [] : List<&2, String>}

# LAW: segments but the last start from the first
law init_cons:
  for s: String
  for t: List<&2, String>
  {Redirect.redirect.init(s <> t) == Redirect.redirect.init.of(t, s)
    : List<&2, String>}

# LAW: the last segment is dropped
law init_last:
  for s: String
  {Redirect.redirect.init.of([], s) == [] : List<&2, String>}

# LAW: every segment before the last is kept, in order
law init_keep:
  for s: String
  for u: String
  for r: List<&2, String>
  {Redirect.redirect.init.of(u <> r, s) == s <> Redirect.redirect.init.of(r, u)
    : List<&2, String>}

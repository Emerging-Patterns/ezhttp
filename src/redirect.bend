# ezhttp/src/redirect: where a GET goes after a response, pure. The client's
# follow loop (client.bend) sends the next GET where this module says and
# decides nothing itself. SPEC.md HTTP-REDIR lists what is guaranteed.
#
# Policy: the client follows redirects for GET only, so every hop is a GET.
# 301, 302, 303, 307 and 308 with a Location are followed; any other status
# stops. A Location is resolved against the current URL as RFC 3986 §5.2
# resolves a reference: an absolute http or https URL is taken as it is, a
# network-path (`//host/...`) takes the current scheme, an absolute path the
# current origin, a query the current path, and a relative path is merged
# with the current path's directory; dot segments are removed. An empty
# Location, a fragment, or another scheme stops. The client gives a chain at
# most `redirect.max()` hops.
import Base
import ./url.bend as Url
import ./http.bend as Http

# what the client does after a response
type Hop is Data:
  Stop{}
  Go{url: String}

# the most hops the client follows (httpx's default is 20)
def redirect.max() -> Nat:
  10n

# whether a status asks the client to go elsewhere (RFC 9110 §15.4.2-9)
def redirect.is(+status: U32) -> Bool:
  Bool.or(U32.is_eq(status, 301), Bool.or(U32.is_eq(status, 302),
    Bool.or(U32.is_eq(status, 303), Bool.or(U32.is_eq(status, 307),
      U32.is_eq(status, 308)))))

# whether a Location is an absolute http or https URL
def redirect.absolute(+loc: String) -> Bool:
  Bool.or(String.starts_with(loc, "http://"),
    String.starts_with(loc, "https://"))

# --- dot segments (RFC 3986 §5.2.4) ---

# the segments kept so far, last first, with the last one dropped
def redirect.pop(out: List<&2, String>) -> List<&2, String>:
  match out:
    case []:
      []
    case _ <> t:
      t

# a path that ends in `.` or `..` keeps its trailing `/`: an empty last segment
def redirect.dots.end(last: Bool, out: List<&2, String>) -> List<&2, String>:
  match last:
    case True{}:
      "" <> out
    case False{}:
      out

# a segment that is not `.`: `..` drops the last kept, any other is kept
def redirect.dots.up(up: Bool, last: Bool, s: String, out: List<&2, String>,
  rest: List<&2, String> -> List<&2, String>) -> List<&2, String>:
  match up:
    case True{}:
      rest(redirect.dots.end(last, redirect.pop(out)))
    case False{}:
      rest(s <> out)

# one segment: `.` is dropped, `..` drops the last kept, any other is kept
def redirect.dots.one(dot: Bool, up: Bool, last: Bool, s: String,
  out: List<&2, String>, rest: List<&2, String> -> List<&2, String>)
  -> List<&2, String>:
  match dot:
    case True{}:
      rest(redirect.dots.end(last, out))
    case False{}:
      redirect.dots.up(up, last, s, out, rest)

# a path's segments with dot segments removed, `out` holding those kept so
# far, last first
def redirect.dots(ss: List<&2, String>, out: List<&2, String>)
  -> List<&2, String>:
  match ss:
    case []:
      List.reverse(&2, String, out)
    case +s <> +t:
      redirect.dots.one(String.eq(s, "."), String.eq(s, ".."),
        List.is_empty(&2, String, t), s, out, o => redirect.dots(t, o))

# the segments after a path's leading `/`, dot segments removed, as a path
def redirect.clean(ss: List<&2, String>) -> String:
  "/" ++ String.join(redirect.dots(ss, []), "/")

# --- merging (RFC 3986 §5.2.3) ---

# every segment but the last, after `s`
def redirect.init.of(t: List<&2, String>, s: String) -> List<&2, String>:
  match t:
    case []:
      []
    case u <> r:
      s <> redirect.init.of(r, u)

# every segment but the last
def redirect.init(ss: List<&2, String>) -> List<&2, String>:
  match ss:
    case []:
      []
    case s <> t:
      redirect.init.of(t, s)

# --- references ---

# a Location's path and its query (with its `?`, "" when it has none)
type Ref is Data:
  Ref{path: String, query: String}

# a Location divided at its first `?`
def redirect.split.of(c: Http.Cut, loc: String) -> Ref:
  match c:
    case Http.NoCut{}:
      Ref{loc, ""}
    case Http.Cut{before, after}:
      Ref{before, "?" ++ after}

# a Location's path and query, its fragment dropped
def redirect.split(+loc: String) -> Ref:
  +bare = Url.frag.drop(loc)
  redirect.split.of(Http.divide(bare, "?"), bare)

# an absolute-path reference's path, dot segments removed, then its query
def redirect.abs.of(r: Ref) -> String:
  match r:
    case Ref{path, query}:
      redirect.clean(List.tail(&2, String, String.split(path, '/'))) ++ query

# a relative-path reference merged with the current path, dot segments
# removed, then its query
def redirect.rel.of(base: String, r: Ref) -> String:
  match r:
    case Ref{path, query}:
      redirect.clean(List.tail(&2, String,
        List.append(&2, String, redirect.init(String.split(base, '/')),
          String.split(path, '/')))) ++ query

# a path without its query
def redirect.base(path: String) -> String:
  Url.query.hier(String.split(path, '?'))

# --- which sort of reference a Location is ---

# what sort of reference a Location that is not an absolute URL is
type Sort is Data:
  Net{}
  Abs{}
  Stay{}
  Query{}
  Rel{}

# a character that ends a reference's first segment
def redirect.schemed.end(+c: Char) -> Bool:
  Bool.or(Char.is_eq(c, '/'), Bool.or(Char.is_eq(c, '?'), Char.is_eq(c, '#')))

# a character that does not end the first segment: a `:` names a scheme
def redirect.schemed.colon(colon: Bool, rest: Unit -> Bool) -> Bool:
  match colon:
    case True{}:
      True{}
    case False{}:
      rest(Unit{})

# one character of the scheme search
def redirect.schemed.at(stop: Bool, colon: Bool, rest: Unit -> Bool) -> Bool:
  match stop:
    case True{}:
      False{}
    case False{}:
      redirect.schemed.colon(colon, rest)

# whether a reference names a scheme: a `:` before its first `/`, `?` or `#`
def redirect.schemed(s: String) -> Bool:
  match s:
    case SNil{}:
      False{}
    case SCon{+c, t}:
      redirect.schemed.at(redirect.schemed.end(c), Char.is_eq(c, ':'),
        _u => redirect.schemed(t))

# a Location the client does not follow: empty, a fragment, another scheme
def redirect.stays(+loc: String) -> Bool:
  Bool.or(String.is_empty(loc), Bool.or(String.starts_with(loc, "#"),
    redirect.schemed(loc)))

# a relative reference: a query, or a relative path
def redirect.sort.rel(query: Bool) -> Sort:
  match query:
    case True{}:
      Query{}
    case False{}:
      Rel{}

# a reference that is not a path from the root: one the client stays on, or
# a relative one
def redirect.sort.stay(stay: Bool, query: Bool) -> Sort:
  match stay:
    case True{}:
      Stay{}
    case False{}:
      redirect.sort.rel(query)

# a reference that is not a network path: an absolute path, or another
def redirect.sort.abs(abs: Bool, stay: Bool, query: Bool) -> Sort:
  match abs:
    case True{}:
      Abs{}
    case False{}:
      redirect.sort.stay(stay, query)

# the sort, from what the Location starts with
def redirect.sort.of(net: Bool, abs: Bool, stay: Bool, query: Bool) -> Sort:
  match net:
    case True{}:
      Net{}
    case False{}:
      redirect.sort.abs(abs, stay, query)

# what sort of reference a Location is
def redirect.sort(+loc: String) -> Sort:
  redirect.sort.of(String.starts_with(loc, "//"), String.starts_with(loc, "/"),
    redirect.stays(loc), String.starts_with(loc, "?"))

# --- the target ---

# a Location of a known sort against the current URL's parts
def redirect.against(scheme: String, host: String, port: U32, path: String,
  +loc: String, k: Sort) -> Maybe<&2, String>:
  match k:
    case Net{}:
      Some{scheme ++ ":" ++ loc}
    case Abs{}:
      Some{scheme ++ "://" ++ host ++ ":" ++ U32.show(port)
        ++ redirect.abs.of(redirect.split(loc))}
    case Stay{}:
      None{}
    case Query{}:
      Some{scheme ++ "://" ++ host ++ ":" ++ U32.show(port)
        ++ redirect.base(path) ++ loc}
    case Rel{}:
      Some{scheme ++ "://" ++ host ++ ":" ++ U32.show(port)
        ++ redirect.rel.of(redirect.base(path), redirect.split(loc))}

# a Location against the current URL, once it is parsed
def redirect.at(l: Url.Loc, +loc: String) -> Maybe<&2, String>:
  match l:
    case Url.Bad{why}:
      None{}
    case Url.Loc{scheme, host, port, path}:
      redirect.against(scheme, host, port, path, loc, redirect.sort(loc))

# a Location once it is known whether it is an absolute URL
def redirect.target.of(url: String, +loc: String, absolute: Bool)
  -> Maybe<&2, String>:
  match absolute:
    case True{}:
      Some{loc}
    case False{}:
      redirect.at(Url.parse(url), loc)

# where a Location sends a client that is at `url`, or None when it is not
# one the client follows
def redirect.target(url: String, +loc: String) -> Maybe<&2, String>:
  redirect.target.of(url, loc, redirect.absolute(loc))

# a resolved target as a hop
def redirect.hop(m: Maybe<&2, String>) -> Hop:
  match m:
    case None{}:
      Stop{}
    case Some{next}:
      Go{next}

# a response once it is known whether its status redirects
def redirect.on(url: String, +loc: String, moved: Bool) -> Hop:
  match moved:
    case True{}:
      redirect.hop(redirect.target(url, loc))
    case False{}:
      Stop{}

# the next hop from `url`, after a response with `status` and Location `loc`
# ("" when it had none), with `left` hops still allowed
def redirect.next(left: Nat, url: String, +status: U32, +loc: String) -> Hop:
  match left:
    case 0n:
      Stop{}
    case 1n+p:
      redirect.on(url, loc, redirect.is(status))

# the next hop after a response's status and headers
def redirect.plan(left: Nat, url: String, +status: U32,
  headers: List<&2, Http.Header>) -> Hop:
  redirect.next(left, url, status, Http.headers.find(headers, "location"))

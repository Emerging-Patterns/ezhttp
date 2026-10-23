# ezhttp/src/redirect: where a GET goes after a response, pure. The client's
# follow loop (client.bend) sends the next GET where this module says and
# decides nothing itself. SPEC.md HTTP-REDIR lists what is guaranteed.
#
# Policy: the client follows redirects for GET only, so every hop is a GET.
# 301, 302, 303, 307 and 308 with a Location are followed; any other status
# stops. A Location is either an absolute http or https URL, taken as it is,
# or an absolute path, resolved against the current URL's scheme, host and
# port. Any other Location (a relative path, `//host/...`, empty) stops. The
# client gives a chain at most `redirect.max()` hops.
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

# whether a Location is an absolute path: one `/`, not two
def redirect.path(+loc: String) -> Bool:
  Bool.and(String.starts_with(loc, "/"),
    Bool.not(String.starts_with(loc, "//")))

# the origin of a URL that came apart, with an absolute path after it
def redirect.join(l: Url.Loc, loc: String) -> Maybe<&2, String>:
  match l:
    case Url.Bad{why}:
      None{}
    case Url.Loc{scheme, host, port, path}:
      Some{scheme ++ "://" ++ host ++ ":" ++ U32.show(port) ++ loc}

# a Location once it is known whether it is an absolute path
def redirect.target.path(url: String, loc: String, path: Bool)
  -> Maybe<&2, String>:
  match path:
    case True{}:
      redirect.join(Url.parse(url), loc)
    case False{}:
      None{}

# a Location once it is known whether it is an absolute URL
def redirect.target.of(url: String, +loc: String, absolute: Bool)
  -> Maybe<&2, String>:
  match absolute:
    case True{}:
      Some{loc}
    case False{}:
      redirect.target.path(url, loc, redirect.path(loc))

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

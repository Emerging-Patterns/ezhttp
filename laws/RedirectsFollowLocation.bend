# `http.get_opts` with `follow` set follows redirects, and so does
# `http.request_opts` when the method is GET. GET is the only method that
# follows them (a POST, PUT or DELETE answers a redirect as its response;
# 303-to-GET is not done), so every hop is a GET with the caller's headers
# and timeout; the first carries the caller's body and the hops after it
# none. A chain is at most 10 hops (httpx allows 20); a chain that runs out
# answers its last response, a redirect. A Location is resolved against the
# current URL as RFC 3986 §5.2 resolves a reference against a base URI. The
# decisions live in `src/redirect.bend`, which does no IO; `client.follow`
# in `src/client.bend` acts on them (trusted in src/client.bend).
#
# For every status 301, 302, 303, 307 or 308 (RFC 9110 §15.4), with hops
# left, whose Location header (read case-insensitively, empty when absent)
# has a target, the next hop is a GET to exactly that target; a Location
# with no target stops the chain.
import Base
import ../src/http.bend as Http
import ../src/redirect.bend as Redirect

# --- redirects ---

# LAW: a redirect status, with hops left, whose Location has a target goes to
# exactly that target
law redir_go:
  for +status: U32
  for e: {True{} == Bool.or(U32.is_eq(status, 301), Bool.or(U32.is_eq(status,
    302), Bool.or(U32.is_eq(status, 303), Bool.or(U32.is_eq(status, 307),
    U32.is_eq(status, 308))))) : Bool}
  for n: Nat
  for url: String
  for +loc: String
  for next: String
  for et: {Some{next} == Redirect.redirect.target(url, loc)
    : Maybe<&2, String>}
  {Redirect.redirect.next(1n+n, url, status, loc) == Redirect.Go{next}
    : Redirect.Hop}

# LAW: a redirect whose Location has no target stops the chain
law redir_no_target:
  for +status: U32
  for left: Nat
  for url: String
  for +loc: String
  for et: {None{} == Redirect.redirect.target(url, loc) : Maybe<&2, String>}
  {Redirect.redirect.next(left, url, status, loc) == Redirect.Stop{}
    : Redirect.Hop}

# LAW: the Location the planner reads is the response's Location header
# (case-insensitive, "" when absent)
law redir_plan_location:
  for left: Nat
  for url: String
  for +status: U32
  for hs: List<&2, Http.Header>
  {Redirect.redirect.plan(left, url, status, hs)
    == Redirect.redirect.next(left, url, status,
      Http.headers.find(hs, "location")) : Redirect.Hop}

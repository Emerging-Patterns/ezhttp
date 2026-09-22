# ezhttp/url: a URL taken apart far enough for an HTTP request. Scheme, host,
# port, and an origin-form path (absolute-path, optional query). Userinfo is
# stripped. The fragment is not part of the request-target.
#
# Shape follows RFC 3986 URI generic syntax: scheme ":" hier-part, with
# hier-part as "//" authority path-abempty ["?" query] ["#" fragment]
# (RFC 3986 §3, §3.1, §3.2, §3.4, §3.5).
import Base

# a url that came apart, or the reason it would not
type Loc is Data:
  Bad{why: String}
  Loc{scheme: String, host: String, port: U32, path: String}

# the port a scheme implies when the authority names none (RFC 3986 §3.2.3;
# HTTPS default 443 is the well-known TLS port, not re-specified here)
def dflt(scheme: String) -> U32:
  Bool.pick(U32, String.eq(scheme, "https"), 443, 80)

# a port that parsed, or the scheme's own when the digits were not digits
def port.num(m: Maybe<&2, U32>, scheme: String) -> U32:
  match m:
    case None{}:
      dflt(scheme)
    case Some{n}:
      n

# the port named after the colon, when there is anything after it
def port.tail(ps: List<&2, String>, scheme: String) -> U32:
  match ps:
    case []:
      dflt(scheme)
    case h <> t:
      port.num(U32.read(h), scheme)

# the port an authority asked for, or the one its scheme implies
def port.of(ps: List<&2, String>, scheme: String) -> U32:
  match ps:
    case []:
      dflt(scheme)
    case h <> t:
      port.tail(t, scheme)

# the host an authority named: everything before the colon
def host.of(ps: List<&2, String>) -> String:
  match ps:
    case []:
      ""
    case h <> t:
      h

# the path a url asked for, "/" when it named none. The leading slash ended
# the authority, so it is put back. Absolute-path form matches RFC 3986
# path-absolute / path-abempty used with an authority (§3.3).
def path.of(ps: List<&2, String>) -> String:
  match ps:
    case []:
      "/"
    case h <> t:
      "/" ++ String.join(t, "/")

# the last piece, or "" when the split was empty
def auth.last.of(m: Maybe<&2, String>) -> String:
  match m:
    case None{}:
      ""
    case Some{hostport}:
      hostport

# the last `@`-separated piece (the hostport). Earlier pieces are userinfo.
def auth.last(ps: List<&2, String>) -> String:
  auth.last.of(List.last(&2, String, ps))

# userinfo is stripped: `user:pass@host` yields `host` (RFC 3986 §3.2.1)
def auth.host(authority: String) -> String:
  auth.last(String.split(authority, '@'))

# the first piece of a `#` split
def frag.drop.of(ps: List<&2, String>) -> String:
  match ps:
    case []:
      ""
    case hier <> _:
      hier

# everything before `#` (RFC 3986 §3.5). The fragment is not a request-target.
def frag.drop(s: String) -> String:
  frag.drop.of(String.split(s, '#'))

# the hier-part before `?`
def query.hier(ps: List<&2, String>) -> String:
  match ps:
    case []:
      ""
    case hier <> _:
      hier

# the query after the first `?`, with later `?` kept (RFC 3986 §3.4)
def query.text(ps: List<&2, String>) -> String:
  match ps:
    case []:
      ""
    case _ <> rest:
      String.join(rest, "?")

# origin-form path: absolute-path, then `?` query when the query is present
def path.target.of(path: String, query: String, empty: Bool) -> String:
  match empty:
    case True{}:
      path
    case False{}:
      path ++ "?" ++ query

# absolute-path ["?" query] (RFC 3986 §3.4, RFC 9112 §3.2.1)
def path.target(path: String, +query: String) -> String:
  path.target.of(path, query, String.eq(query, ""))

# a url whose authority is now split on its colon
def parse.auth(+scheme: String, +au: List<&2, String>, path: String) -> Loc:
  Loc{scheme, host.of(au), port.of(au, scheme), path}

# authority (userinfo stripped) and origin-form path
def parse.parts(+scheme: String, +ps: List<&2, String>, query: String) -> Loc:
  parse.auth(scheme, String.split(auth.host(host.of(ps)), ':'),
    path.target(path.of(ps), query))

# hier-part split on `?`
def parse.q(+scheme: String, +ps: List<&2, String>) -> Loc:
  parse.parts(scheme, String.split(query.hier(ps), '/'), query.text(ps))

# fragment stripped, then query split from the hier-part
def parse.hier(+scheme: String, +rest: String) -> Loc:
  parse.q(scheme, String.split(frag.drop(rest), '?'))

# what follows the scheme, once it is known whether it opens with `//`
def parse.body(+scheme: String, +rest: String, slashes: Bool) -> Loc:
  match slashes:
    case False{}:
      Bad{scheme ++ ":" ++ rest ++ " has no //"}
    case True{}:
      parse.hier(scheme, String.drop(rest, 2n))

# what follows the scheme, judged on its `//`
def parse.rest(+scheme: String, +rest: String) -> Loc:
  parse.body(scheme, rest, String.starts_with(rest, "//"))

# a url split on its colons: the first piece is the scheme, and a colon in the
# path survives because the rest is joined back up
def parse.scheme(ps: List<&2, String>) -> Loc:
  match ps:
    case []:
      Bad{"an empty url"}
    case h <> t:
      parse.rest(String.to_lower(h), String.join(t, ":"))

# a url in pieces, or the reason it is not one
def parse(url: String) -> Loc:
  parse.scheme(String.split(url, ':'))

# a parsed url on one line, for a test to read
def show(l: Loc) -> String:
  match l:
    case Bad{why}:
      "bad " ++ why
    case Loc{scheme, host, port, path}:
      scheme ++ " " ++ host ++ " " ++ U32.show(port) ++ " " ++ path

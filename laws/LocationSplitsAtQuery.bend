# A Location's fragment is dropped, and what is left is cut at its first
# `?` into its path and its query (RFC 3986 §3.4, §3.5); with no `?` it is
# all path and no query.
import Base
import ../src/http.bend as Http
import ../src/url.bend as Url
import ../src/redirect.bend as Redirect

# LAW (RFC 3986 §3.4, §3.5): a Location with a `?` is its path before it and
# its query from it, its fragment dropped
law split_query:
  for +loc: String
  for p: String
  for q: String
  for e: {Http.Cut{p, q} == Http.divide(Url.frag.drop(loc), "?") : Http.Cut}
  {Redirect.redirect.split(loc) == Redirect.Ref{p, "?" ++ q} : Redirect.Ref}

# LAW: a Location with no `?` is all path, its fragment dropped
law split_plain:
  for +loc: String
  for e: {Http.NoCut{} == Http.divide(Url.frag.drop(loc), "?") : Http.Cut}
  {Redirect.redirect.split(loc) == Redirect.Ref{Url.frag.drop(loc), ""}
    : Redirect.Ref}

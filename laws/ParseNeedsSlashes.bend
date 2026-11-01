import Base
import ../src/url.bend as Url

# LAW (RFC 3986 §3): hier-part without "//" is refused
law parse_needs_slashes:
  for +scheme: String
  for +rest: String
  for e: {False{} == String.starts_with(rest, "//") : Bool}
  {Url.parse.rest(scheme, rest)
    == Url.Bad{scheme ++ ":" ++ rest ++ " has no //"}
    : Url.Loc}

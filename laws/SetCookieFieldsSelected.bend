# For every list of header fields, `cookie_from_headers` reads the values of
# exactly the fields named Set-Cookie (compared case-insensitively, RFC 9110
# §5.1), in order.
import Base
import ../src/http.bend as Http
import ../src/cookie.bend as Cookie
import ../src/echo.bend as Echo

# LAW: no header fields, no Set-Cookie values
law ck_values_nil:
  for hs: List<&2, Http.Header>
  for e: {[] == hs : List<&2, Http.Header>}
  {Echo.values(hs) == [] : List<&2, String>}

# LAW (RFC 9110 §5.1): a field named Set-Cookie in any case gives its value,
# in order
law ck_values_hit:
  for +name: String
  for value: String
  for t: List<&2, Http.Header>
  for e: {True{} == String.eq(String.to_lower(name), "set-cookie") : Bool}
  {Echo.values(Http.H{name, value} <> t) == value <> Echo.values(t)
    : List<&2, String>}

# LAW: any other field gives nothing
law ck_values_miss:
  for +name: String
  for value: String
  for t: List<&2, Http.Header>
  for e: {False{} == String.eq(String.to_lower(name), "set-cookie") : Bool}
  {Echo.values(Http.H{name, value} <> t) == Echo.values(t)
    : List<&2, String>}

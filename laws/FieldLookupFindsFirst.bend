# For every header list and field name, a lookup compares names
# case-insensitively (RFC 9110 §5.1): the first field whose lower-case name
# is the asked name's lower-case form gives its value, however the two were
# spelled, and every field before it with another name is passed over, so
# of a repeated name the first field is the one found (RFC 9110 §5.2).
import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §5.1, §5.2): a field whose name matches, case aside, is found
law headers_find_first:
  for n: String
  for v: String
  for t: List<&2, Http.Header>
  for +name: String
  for e: {True{} == String.eq(String.to_lower(n), String.to_lower(name))
    : Bool}
  {Http.headers.find(Http.H{n, v} <> t, name) == v : String}

# LAW (RFC 9110 §5.1): a field with another name is passed over
law headers_find_skips:
  for n: String
  for v: String
  for t: List<&2, Http.Header>
  for +name: String
  for e: {False{} == String.eq(String.to_lower(n), String.to_lower(name))
    : Bool}
  {Http.headers.find(Http.H{n, v} <> t, name) == Http.headers.find(t, name)
    : String}

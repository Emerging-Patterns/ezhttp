# For every Set-Cookie line, a name-value-pair with no `=`, or whose name
# is empty once trimmed, sets no cookie (RFC 6265 §5.2 steps 2 and 5).
import Base
import ../src/http.bend as Http
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.2 step 2): no `=`, no cookie
law cookie_from_no_equals:
  for pair: String
  for attrs: List<&2, String>
  {Cookie.cookie.from(pair, attrs, Http.NoCut{}) == None{}
    : Maybe<&2, Cookie.Cookie>}

# LAW (§5.2 step 5): an empty name, no cookie
law cookie_from_empty_name:
  for name: String
  for value: String
  for attrs: List<&2, String>
  {Cookie.cookie.from.name(name, value, attrs, True{}) == None{}
    : Maybe<&2, Cookie.Cookie>}

# For every field name, looking it up in a header list with no fields gives
# the empty value: a field the message did not send reads as "".
import Base
import ../src/http.bend as Http

# LAW: an absent field reads as empty
law headers_find_missing:
  for +name: String
  {Http.headers.find([], name) == "" : String}

import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.4): the Cookie header joins pairs with `; ` and drops an
# empty name
law cookie_request_joins:
  {Cookie.cookie.join([Cookie.cookie.new("a", "b"), Cookie.cookie.new("c", "d"),
      Cookie.cookie.new("", "x")])
    == "a=b; c=d" : String}

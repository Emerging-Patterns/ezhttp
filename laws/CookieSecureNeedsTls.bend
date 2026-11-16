# For every request, a Secure cookie may be sent exactly when the request
# is over TLS (RFC 6265 §5.4 step 1).
import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.4): a Secure cookie rides only on TLS
law cookie_secure_tls:
  for +tls: Bool
  {Cookie.cookie.send.secure(tls, True{}) == tls : Bool}

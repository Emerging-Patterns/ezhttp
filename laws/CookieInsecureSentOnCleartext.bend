# For every request, TLS or not, a cookie without Secure may be sent
# (RFC 6265 §5.4 step 1).
import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.4): a cookie without Secure rides on any transport
law cookie_insecure_any:
  for tls: Bool
  {Cookie.cookie.send.secure(tls, False{}) == True{} : Bool}

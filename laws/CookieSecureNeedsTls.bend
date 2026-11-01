import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.4): a Secure cookie is not sent on a cleartext request
law cookie_secure_needs_tls:
  {Cookie.cookie.send.secure(False{}, True{}) == False{} : Bool}

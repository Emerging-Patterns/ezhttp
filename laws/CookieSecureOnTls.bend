import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.4): a Secure cookie is sent when the request is TLS
law cookie_secure_on_tls:
  {Cookie.cookie.send.secure(True{}, True{}) == True{} : Bool}

import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.4): a cookie that is not Secure is sent on cleartext
law cookie_insecure_on_tcp:
  {Cookie.cookie.send.secure(False{}, False{}) == True{} : Bool}

import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.1.4): one slash is not enough for a directory default-path
law cookie_default_path_one_slash:
  {Cookie.cookie.default_path("/") == "/" : String}

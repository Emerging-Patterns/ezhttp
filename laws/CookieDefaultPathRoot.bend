import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.1.4): fewer than two slashes means default-path `/`
law cookie_default_path_root:
  {Cookie.cookie.default_path("/a") == "/" : String}

import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.1.4): default-path is the directory of a path with two slashes
law cookie_default_path_dir:
  {Cookie.cookie.default_path("/a/b") == "/a" : String}

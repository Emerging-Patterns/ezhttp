import Base
import ../src/url.bend as Url

# LAW: a url that came apart opens with its scheme
law url_show_opens_with_scheme:
  for +scheme: String
  for host: String
  for port: U32
  for path: String
  {String.starts_with(Url.show(Url.Loc{scheme, host, port, path}), scheme)
    == True{} : Bool}

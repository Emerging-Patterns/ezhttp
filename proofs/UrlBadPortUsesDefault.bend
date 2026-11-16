# proofs of laws/UrlBadPortUsesDefault.bend
import Base
import ../src/url.bend as Url
import ../laws/UrlBadPortUsesDefault.bend as Laws

def Laws.port_junk(_host, _port, _rest, scheme, e):
  %e : {Url.port.num(_, scheme) == Url.dflt(scheme) : U32}
  {==}

# proofs of laws/UrlHttpsExplicitPort.bend
import Base
import ../src/url.bend as Url
import ../laws/UrlHttpsExplicitPort.bend as Laws

def Laws.port_explicit(_host, _port, _rest, n, scheme, e):
  %e : {Url.port.num(_, scheme) == n : U32}
  {==}

# proofs of laws/UrlUserinfoLastAt.bend
import Base
import ../src/url.bend as Url
import ../laws/UrlUserinfoLastAt.bend as Laws

def Laws.host_after_last_at(_authority, hostport, e):
  %e : {Url.auth.last.of(_) == hostport : String}
  {==}

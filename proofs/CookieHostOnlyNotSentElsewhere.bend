# proofs of laws/CookieHostOnlyNotSentElsewhere.bend
import Base
import ../src/cookie.bend as Cookie
import ../laws/CookieHostOnlyNotSentElsewhere.bend as Laws

def Laws.cookie_send_domain_miss(
  _host,
  req,
  tls,
  _n,
  _v,
  _x,
  _m,
  _domain,
  path,
  secure,
  _h,
  _ss,
  _host_only,
  e
):
  %e : {Cookie.cookie.send.domain(req, tls, secure, path, _) == False{} : Bool}
  {==}

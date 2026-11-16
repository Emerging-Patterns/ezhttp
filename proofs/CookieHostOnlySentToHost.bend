# proofs of laws/CookieHostOnlySentToHost.bend
import Base
import ../src/cookie.bend as Cookie
import ../laws/CookieHostOnlySentToHost.bend as Laws

def Laws.cookie_send_domain_hit(
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
  %e : {Cookie.cookie.send.domain(req, tls, secure, path, _)
    == Cookie.cookie.send.path(tls, secure, Cookie.cookie.path_ok(req, path))
    : Bool}
  {==}

def Laws.cookie_send_path_miss(_tls, _secure):
  {==}

def Laws.cookie_send_path_hit(_tls, _secure):
  {==}

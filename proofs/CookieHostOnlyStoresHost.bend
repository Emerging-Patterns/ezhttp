# proofs of laws/CookieHostOnlyStoresHost.bend
import Base
import ../src/cookie.bend as Cookie
import ../laws/CookieHostOnlyStoresHost.bend as Laws

def Laws.cookie_receive(_n, _v, _x, _m, _d, _p, _s, _h, _ss, _ho, _host, _req):
  {==}

def Laws.cookie_fill_domain_host_only(_domain, _host):
  {==}

def Laws.cookie_fill_domain_set(_domain, _host):
  {==}

def Laws.cookie_fill_path_empty(path, req, e):
  %e : {Cookie.cookie.fill_path.of(path, req, _) == Cookie.cookie.default_path(req)
    : String}
  {==}

def Laws.cookie_fill_path_set(path, req, e):
  %e : {Cookie.cookie.fill_path.of(path, req, _) == path : String}
  {==}

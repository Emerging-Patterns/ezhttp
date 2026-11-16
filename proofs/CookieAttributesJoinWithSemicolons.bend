# proofs of laws/CookieAttributesJoinWithSemicolons.bend
import Base
import ../src/cookie.bend as Cookie
import ../laws/CookieAttributesJoinWithSemicolons.bend as Laws

def Laws.cookie_line(_n, _v, _x, _m, _d, _p, _s, _h, _ss, _ho):
  {==}

def Laws.cookie_opt_empty(prefix, value, e):
  %e : {Cookie.cookie.opt.of(prefix, value, _) == "" : String}
  {==}

def Laws.cookie_opt_set(prefix, value, e):
  %e : {Cookie.cookie.opt.of(prefix, value, _) == prefix ++ value : String}
  {==}

def Laws.cookie_mark_on(_label):
  {==}

def Laws.cookie_mark_off(_label):
  {==}

def Laws.cookie_domain_text_host_only(_domain):
  {==}

def Laws.cookie_domain_text_set(_domain):
  {==}

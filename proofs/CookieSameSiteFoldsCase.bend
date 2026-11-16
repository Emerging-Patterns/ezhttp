# proofs of laws/CookieSameSiteFoldsCase.bend
import Base
import ../src/cookie.bend as Cookie
import ../laws/CookieSameSiteFoldsCase.bend as Laws

def Laws.cookie_named_samesite(_c, _value):
  {==}

def Laws.cookie_site_lax(raw, e):
  %e : {Cookie.cookie.site.lax(String.to_lower(raw), _) == "Lax" : String}
  {==}

def Laws.cookie_site_strict(raw, e1, e2):
  %e1 : {Cookie.cookie.site.lax(String.to_lower(raw), _) == "Strict" : String}
  %e2 : {Cookie.cookie.site.strict(String.to_lower(raw), _) == "Strict" : String}
  {==}

def Laws.cookie_site_none(raw, e1, e2, e3):
  %e1 : {Cookie.cookie.site.lax(String.to_lower(raw), _) == "None" : String}
  %e2 : {Cookie.cookie.site.strict(String.to_lower(raw), _) == "None" : String}
  %e3 : {Cookie.cookie.site.none(String.to_lower(raw), _) == "None" : String}
  {==}

def Laws.cookie_site_unknown(raw, e1, e2, e3):
  %e1 : {Cookie.cookie.site.lax(String.to_lower(raw), _) == "" : String}
  %e2 : {Cookie.cookie.site.strict(String.to_lower(raw), _) == "" : String}
  %e3 : {Cookie.cookie.site.none(String.to_lower(raw), _) == "" : String}
  {==}

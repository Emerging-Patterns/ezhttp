# proofs of laws/CookieMaxAgeSetsAge.bend
import Base
import ../laws/CookieMaxAgeSetsAge.bend as Laws

# cookie_age_sets holds by unfolding cookie.age
def Laws.cookie_age_sets(
  _name,
  _value,
  _expires,
  _max_age,
  _domain,
  _path,
  _secure,
  _http_only,
  _same_site,
  _host_only,
  _age
):
  {==}

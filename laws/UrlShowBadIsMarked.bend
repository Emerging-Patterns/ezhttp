import Base
import ../src/url.bend as Url

# LAW: a url that would not come apart says so first
law url_show_bad_is_marked:
  for why: String
  {String.starts_with(Url.show(Url.Bad{why}), "bad ") == True{} : Bool}

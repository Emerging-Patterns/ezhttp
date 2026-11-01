# `&` is written as `&amp;`, `<` as `&lt;`, `>` as `&gt;`, `"` as `&#34;`
# and `'` as `&#39;`.
import Base
import ../src/html.bend as Html

# LAW: `&` is written as `&amp;`
law html_amp:
  for rest: String
  {Html.one('&', rest) == "&amp;" ++ rest : String}

# LAW: `<` is written as `&lt;`
law html_lt:
  for rest: String
  {Html.one('<', rest) == "&lt;" ++ rest : String}

# LAW: `>` is written as `&gt;`
law html_gt:
  for rest: String
  {Html.one('>', rest) == "&gt;" ++ rest : String}

# LAW: `"` is written as `&#34;`
law html_dq:
  for rest: String
  {Html.one('"', rest) == "&#34;" ++ rest : String}

# LAW: `'` is written as `&#39;`
law html_sq:
  for rest: String
  {Html.one('\'', rest) == "&#39;" ++ rest : String}

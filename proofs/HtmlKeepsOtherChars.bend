# proofs of laws/HtmlKeepsOtherChars.bend
import Base
import ../src/html.bend as Html
import ../laws/HtmlKeepsOtherChars.bend as Laws

def Laws.html_other(c, e1, e2, e3, e4, e5, rest):
  %e1 : {Html.one.amp(c, rest, _) == SCon{c, rest} : String}
  %e2 : {Html.one.lt(c, rest, _) == SCon{c, rest} : String}
  %e3 : {Html.one.gt(c, rest, _) == SCon{c, rest} : String}
  %e4 : {Html.one.dq(c, rest, _) == SCon{c, rest} : String}
  %e5 : {Html.one.sq(c, rest, _) == SCon{c, rest} : String}
  {==}

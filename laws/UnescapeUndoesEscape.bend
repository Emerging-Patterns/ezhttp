# For every string, `html_unescape` of its `html_escape`
# (laws/HtmlEscapeCharByChar.bend) is the string: `&amp;`, `&lt;`, `&gt;`,
# `&#34;` and `&#39;` read back as `&`, `<`, `>`, `"` and `'`, and every
# other character as itself.
import Base
import ../src/html.bend as Html
import ../src/unescape.bend as Ref

# LAW: unescaping undoes html_escape: for every string, html_unescape of its
# escape is the string
law ref_round:
  for s: String
  {Ref.unescape(Html.escape(s)) == s : String}

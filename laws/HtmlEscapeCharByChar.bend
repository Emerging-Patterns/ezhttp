# `html_escape(s)` (`src/html.bend`) escapes text for HTML the way
# markupsafe's `escape` and Jinja's autoescape do.
#
# For every string, the escape writes its characters in order, each one
# independently of the others, and nothing else.
import Base
import ../src/html.bend as Html

# --- HTML escaping ---

# LAW: escaping a string is escaping it in front of nothing
law html_escape_onto:
  for s: String
  {Html.escape(s) == Html.escape.onto(s, "") : String}

# LAW: nothing is written for the empty string
law html_nil:
  for rest: String
  {Html.escape.onto("", rest) == rest : String}

# LAW: a string is written one character at a time, the first character's
# writing followed by the rest's
law html_cons:
  for +c: Char
  for t: String
  for rest: String
  {Html.escape.onto(SCon{c, t}, rest) == Html.one(c, Html.escape.onto(t, rest))
    : String}

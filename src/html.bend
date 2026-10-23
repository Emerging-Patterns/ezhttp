# ezhttp/src/html: HTML escaping, the way markupsafe.escape and Jinja's
# autoescape do it. `&`, `<`, `>`, `"` and `'` are written as `&amp;`, `&lt;`,
# `&gt;`, `&#34;` and `&#39;`; every other character is written as itself.
# SPEC.md HTTP-HTML lists what is guaranteed.
import Base

# one character that is not `&`, `<`, `>` or `"`, as `'` or as itself
def one.sq(+c: Char, rest: String, hit: Bool) -> String:
  match hit:
    case True{}:
      "&#39;" ++ rest
    case False{}:
      SCon{c, rest}

# one character that is not `&`, `<` or `>`
def one.dq(+c: Char, rest: String, hit: Bool) -> String:
  match hit:
    case True{}:
      "&#34;" ++ rest
    case False{}:
      one.sq(c, rest, Char.is_eq(c, '\''))

# one character that is not `&` or `<`
def one.gt(+c: Char, rest: String, hit: Bool) -> String:
  match hit:
    case True{}:
      "&gt;" ++ rest
    case False{}:
      one.dq(c, rest, Char.is_eq(c, '"'))

# one character that is not `&`
def one.lt(+c: Char, rest: String, hit: Bool) -> String:
  match hit:
    case True{}:
      "&lt;" ++ rest
    case False{}:
      one.gt(c, rest, Char.is_eq(c, '>'))

# one character, once it is known whether it is `&`
def one.amp(+c: Char, rest: String, hit: Bool) -> String:
  match hit:
    case True{}:
      "&amp;" ++ rest
    case False{}:
      one.lt(c, rest, Char.is_eq(c, '<'))

# one character as it is escaped, followed by `rest`
def one(+c: Char, rest: String) -> String:
  one.amp(c, rest, Char.is_eq(c, '&'))

# a string escaped, each character in turn, followed by `rest`
def escape.onto(s: String, rest: String) -> String:
  match s:
    case SNil{}:
      rest
    case SCon{+c, tail}:
      one(c, escape.onto(tail, rest))

# a string escaped for HTML text or a quoted attribute value
def escape(s: String) -> String:
  escape.onto(s, "")

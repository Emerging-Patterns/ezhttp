# ezhttp/src/echo: the Cookie request header a client sends back after
# Set-Cookie fields, reduced to names and values (RFC 6265 §5.2 parsing,
# §5.3 step 11 replacement, §5.4 serialization). No attribute is read: no
# Domain, Path, Expires, Max-Age, Secure or HttpOnly, so nothing expires and
# every cookie goes back. Pure. SPEC.md HTTP-CK lists what is guaranteed.
import Base
import ./http.bend as Http
import ./qs.bend as Qs

# whitespace as RFC 6265 §5.2 strips it: SP or HTAB (RFC 5234 WSP)
def wsp(+c: Char) -> Bool:
  Bool.or(Char.is_eq(c, ' '), Char.is_eq(c, '\t'))

# one character of the leading strip: dropped, and the strip goes on, when
# it is WSP
def wsp.lead.if(t: String, +h: Char, space: Bool, rest: Unit -> String)
  -> String:
  match space:
    case True{}:
      rest(Unit{})
    case False{}:
      SCon{h, t}

# a string without its leading WSP
def wsp.lead(s: String) -> String:
  match s:
    case SNil{}:
      SNil{}
    case SCon{+h, +t}:
      wsp.lead.if(t, h, wsp(h), _u => wsp.lead(t))

# a string without its leading and trailing WSP
def wsp.trim(s: String) -> String:
  String.reverse(wsp.lead(String.reverse(wsp.lead(s))))

# a pair whose name is known: ignored when the name is empty (§5.2 step 5)
def pair.named(+name: String, value: String, empty: Bool) -> Maybe<&2, Qs.Kv()>:
  match empty:
    case True{}:
      None{}
    case False{}:
      Some{(name, value)}

# the name-value-pair cut at its first `=`: none without one (§5.2 step 2),
# else the name before it and the value after it, each without leading and
# trailing WSP (steps 3, 4)
def pair.cut(m: Maybe<&2, Qs.Kv()>) -> Maybe<&2, Qs.Kv()>:
  match m:
    case None{}:
      None{}
    case Some{(before, after)}:
      +name = wsp.trim(before)
      pair.named(name, wsp.trim(after), String.is_empty(name))

# the cookie one Set-Cookie field value sets: its name-value-pair is the text
# before its first `;`, all of it without one (§5.2 step 1)
def pair(line: String) -> Maybe<&2, Qs.Kv()>:
  pair.cut(Qs.cut(Http.first(String.split(line, ';'))))

# one stored cookie, once it is known whether it has the new one's name:
# that one takes the new value in its place, any other is kept and the rest
# of the store looked at
def put.at(key: String, old: String, value: String, t: List<&2, Qs.Kv()>,
  hit: Bool, rest: Unit -> List<&2, Qs.Kv()>) -> List<&2, Qs.Kv()>:
  match hit:
    case True{}:
      (key, value) <> t
    case False{}:
      (key, old) <> rest(Unit{})

# a cookie put in a store: a stored one of the same name (compared exactly)
# keeps its place and takes the new value (§5.3 step 11.3 keeps its
# creation-time, which orders it, §5.4 step 2), else it goes after the others
def put(jar: List<&2, Qs.Kv()>, +name: String, +value: String)
  -> List<&2, Qs.Kv()>:
  match jar:
    case []:
      [(name, value)]
    case (+key, old) <> +t:
      put.at(key, old, value, t, String.eq(key, name),
        _u => put(t, name, value))

# a store after one Set-Cookie field value: unchanged when it sets nothing
def add(jar: List<&2, Qs.Kv()>, m: Maybe<&2, Qs.Kv()>) -> List<&2, Qs.Kv()>:
  match m:
    case None{}:
      jar
    case Some{(name, value)}:
      put(jar, name, value)

# a store after Set-Cookie field values, in the order they came
def store(lines: List<&2, String>, jar: List<&2, Qs.Kv()>)
  -> List<&2, Qs.Kv()>:
  match lines:
    case []:
      jar
    case l <> t:
      store(t, add(jar, pair(l)))

# one cookie in the Cookie header: its name, `=`, its value (§5.4 step 4.1)
def one(name: String, value: String) -> String:
  name ++ "=" ++ value

# the cookies after the first, each after `; ` (§5.4 step 4.2)
def more(jar: List<&2, Qs.Kv()>) -> String:
  match jar:
    case []:
      ""
    case (name, value) <> t:
      "; " ++ one(name, value) ++ more(t)

# a store as the Cookie header's value, empty for an empty store
def line(jar: List<&2, Qs.Kv()>) -> String:
  match jar:
    case []:
      ""
    case (name, value) <> t:
      one(name, value) ++ more(t)

# the Cookie header value to send after these Set-Cookie field values
def echo(lines: List<&2, String>) -> String:
  line(store(lines, []))

# one header field: its value in front of the rest when it is Set-Cookie
def values.put(value: String, rest: List<&2, String>, hit: Bool)
  -> List<&2, String>:
  match hit:
    case True{}:
      value <> rest
    case False{}:
      rest

# the values of the Set-Cookie fields among response headers, in order (field
# names compared case-insensitively, RFC 9110 §5.1)
def values(hs: List<&2, Http.Header>) -> List<&2, String>:
  match hs:
    case []:
      []
    case Http.H{name, value} <> t:
      values.put(value, values(t), String.eq(String.to_lower(name),
        "set-cookie"))

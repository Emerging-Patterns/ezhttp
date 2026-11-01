# `cookie_from_set_cookies(values)` and `cookie_from_headers(headers)`
# (`src/echo.bend`) give the `Cookie` request header value a client sends
# after a response's `Set-Cookie` fields, keeping only names and values: no
# attribute is read, so nothing expires and every cookie goes back.
#
# For every list of Set-Cookie field values, the cookies they set are stored
# in order: a cookie whose name (compared exactly) is already stored
# replaces that one's value in its place (§5.3 step 11.3 keeps the old
# cookie's creation-time, which §5.4 step 2 orders by), any other goes after
# those stored. The Cookie header value is each stored cookie as its name,
# `=` and its value (§5.4 step 4.1), with `; ` between two (step 4.2), and
# empty when none is stored.
import Base
import ../src/qs.bend as Qs
import ../src/echo.bend as Echo

# LAW: the header sent back is the store after the values, written out
law ck_echo:
  for lines: List<&2, String>
  {Echo.echo(lines) == Echo.line(Echo.store(lines, [])) : String}

# LAW: with no more values, the store is as it is
law ck_store_nil:
  for jar: List<&2, Qs.Kv()>
  {Echo.store([], jar) == jar : List<&2, Qs.Kv()>}

# LAW: values are stored in the order they came
law ck_store_cons:
  for l: String
  for t: List<&2, String>
  for jar: List<&2, Qs.Kv()>
  {Echo.store(l <> t, jar) == Echo.store(t, Echo.add(jar, Echo.pair(l)))
    : List<&2, Qs.Kv()>}

# LAW: a value that sets nothing leaves the store
law ck_add_none:
  for jar: List<&2, Qs.Kv()>
  {Echo.add(jar, None{}) == jar : List<&2, Qs.Kv()>}

# LAW: a cookie is put in the store
law ck_add_some:
  for jar: List<&2, Qs.Kv()>
  for name: String
  for value: String
  {Echo.add(jar, Some{(name, value)}) == Echo.put(jar, name, value)
    : List<&2, Qs.Kv()>}

# LAW (§5.3): a cookie no stored one is named like goes last
law ck_put_nil:
  for +name: String
  for +value: String
  {Echo.put([], name, value) == [(name, value)] : List<&2, Qs.Kv()>}

# LAW (§5.3 step 11): a stored cookie of the same name takes the new value
# in its place
law ck_put_hit:
  for +key: String
  for old: String
  for +t: List<&2, Qs.Kv()>
  for +name: String
  for +value: String
  for e: {True{} == String.eq(key, name) : Bool}
  {Echo.put((key, old) <> t, name, value) == (key, value) <> t
    : List<&2, Qs.Kv()>}

# LAW: any other stored cookie stays, and the rest of the store is looked at
law ck_put_miss:
  for +key: String
  for old: String
  for +t: List<&2, Qs.Kv()>
  for +name: String
  for +value: String
  for e: {False{} == String.eq(key, name) : Bool}
  {Echo.put((key, old) <> t, name, value) == (key, old) <> Echo.put(t, name,
    value) : List<&2, Qs.Kv()>}

# LAW (§5.4): an empty store sends the empty value
law ck_line_nil:
  for jar: List<&2, Qs.Kv()>
  for e: {[] == jar : List<&2, Qs.Kv()>}
  {Echo.line(jar) == "" : String}

# LAW (§5.4 step 4): the first cookie, then the others
law ck_line_cons:
  for name: String
  for value: String
  for t: List<&2, Qs.Kv()>
  {Echo.line((name, value) <> t) == Echo.one(name, value) ++ Echo.more(t)
    : String}

# LAW: after the last cookie, nothing
law ck_more_nil:
  for jar: List<&2, Qs.Kv()>
  for e: {[] == jar : List<&2, Qs.Kv()>}
  {Echo.more(jar) == "" : String}

# LAW (§5.4 step 4.2): each cookie after the first follows `; `
law ck_more_cons:
  for name: String
  for value: String
  for t: List<&2, Qs.Kv()>
  {Echo.more((name, value) <> t) == "; " ++ Echo.one(name, value)
    ++ Echo.more(t) : String}

# LAW (§5.4 step 4.1): a cookie is its name, `=` and its value
law ck_one:
  for name: String
  for value: String
  {Echo.one(name, value) == name ++ "=" ++ value : String}

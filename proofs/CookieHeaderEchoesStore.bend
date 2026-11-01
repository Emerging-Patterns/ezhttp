# proofs of laws/CookieHeaderEchoesStore.bend
import Base
import ../src/qs.bend as Qs
import ../src/echo.bend as Echo
import ../laws/CookieHeaderEchoesStore.bend as Laws

def Laws.ck_echo(_lines):
  {==}

def Laws.ck_store_nil(_jar):
  {==}

def Laws.ck_store_cons(_l, _t, _jar):
  {==}

def Laws.ck_add_none(_jar):
  {==}

def Laws.ck_add_some(_jar, _name, _value):
  {==}

def Laws.ck_put_nil(_name, _value):
  {==}

def Laws.ck_put_hit(key, old, t, name, value, e):
  %e : {Echo.put.at(key, old, value, t, _, _u => Echo.put(t, name, value))
    == (key, value) <> t : List<&2, Qs.Kv()>}
  {==}

def Laws.ck_put_miss(key, old, t, name, value, e):
  %e : {Echo.put.at(key, old, value, t, _, _u => Echo.put(t, name, value))
    == (key, old) <> Echo.put(t, name, value) : List<&2, Qs.Kv()>}
  {==}

def Laws.ck_line_nil(_jar, e):
  %e : {Echo.line(_) == "" : String}
  {==}

def Laws.ck_line_cons(_name, _value, _t):
  {==}

def Laws.ck_more_nil(_jar, e):
  %e : {Echo.more(_) == "" : String}
  {==}

def Laws.ck_more_cons(_name, _value, _t):
  {==}

def Laws.ck_one(_name, _value):
  {==}

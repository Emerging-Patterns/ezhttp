# proofs of laws/QueryGetLastWins.bend
import Base
import ../src/qs.bend as Qs
import ../laws/QueryGetLastWins.bend as Laws

def Laws.qs_get_nil(_name):
  {==}

def Laws.qs_get_later(key, value, _t, name, x, e):
  %e : {Qs.get.pick(_, value, String.eq(key, name)) == Some{x}
    : Maybe<&2, String>}
  {==}

def Laws.qs_get_here(key, value, _t, name, e1, e2):
  %e1 : {Qs.get.pick(_, value, String.eq(key, name)) == Some{value}
    : Maybe<&2, String>}
  %e2 : {Qs.get.pick(None{}, value, _) == Some{value} : Maybe<&2, String>}
  {==}

def Laws.qs_get_miss(key, value, _t, name, e1, e2):
  %e1 : {Qs.get.pick(_, value, String.eq(key, name)) == None{}
    : Maybe<&2, String>}
  %e2 : {Qs.get.pick(None{}, value, _) == None{} : Maybe<&2, String>}
  {==}

# For every list of pairs and name, `query_get` answers the value of the
# last pair whose name is exactly that name, and none when no pair has it
# (last wins, as `dict(parse_qsl(...))` does).
import Base
import ../src/qs.bend as Qs

# LAW: no pairs give no value
law qs_get_nil:
  for name: String
  {Qs.get([], name) == None{} : Maybe<&2, String>}

# LAW: a later pair with the name wins
law qs_get_later:
  for key: String
  for value: String
  for t: List<&2, Qs.Kv()>
  for +name: String
  for x: String
  for e: {Some{x} == Qs.get(t, name) : Maybe<&2, String>}
  {Qs.get((key, value) <> t, name) == Some{x} : Maybe<&2, String>}

# LAW: with no later pair with the name, this one's value when it has it
law qs_get_here:
  for key: String
  for value: String
  for t: List<&2, Qs.Kv()>
  for +name: String
  for e1: {None{} == Qs.get(t, name) : Maybe<&2, String>}
  for e2: {True{} == String.eq(key, name) : Bool}
  {Qs.get((key, value) <> t, name) == Some{value} : Maybe<&2, String>}

# LAW: and none when it does not
law qs_get_miss:
  for key: String
  for value: String
  for t: List<&2, Qs.Kv()>
  for +name: String
  for e1: {None{} == Qs.get(t, name) : Maybe<&2, String>}
  for e2: {False{} == String.eq(key, name) : Bool}
  {Qs.get((key, value) <> t, name) == None{} : Maybe<&2, String>}

# `Qs.cut` cuts a text at its first `=` into the text before it and the
# text after it, and does not cut a text with no `=`.
import Base
import ../src/qs.bend as Qs
import ./defs/CharacterAbsent.bend as D1

# LAW: a text with no `=` before one is cut at that one
law qs_cut_found:
  for +s: String
  for r: String
  for +e: {D1.avoids(s, '=') == True{} : Bool}
  {Qs.cut(String.append(s, SCon{'=', r})) == Some{(s, r)}
    : Maybe<&2, Qs.Kv()>}

# LAW: a text with no `=` is not cut
law qs_cut_none:
  for +s: String
  for +e: {D1.avoids(s, '=') == True{} : Bool}
  {Qs.cut(s) == None{} : Maybe<&2, Qs.Kv()>}

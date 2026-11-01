# `String.split` cuts a string at every occurrence of a character: a string
# that holds it nowhere is one piece, and one that holds it first at a
# known place splits there.
import Base
import ./defs/CharacterAbsent.bend as D1

# LAW: a string that holds the character nowhere splits into itself
law split_whole:
  for +s: String
  for +c: Char
  for +e: {D1.avoids(s, c) == True{} : Bool}
  {String.split(s, c) == [s] : List<&2, String>}

# LAW: a string that holds the character first at a known place splits there
law split_cut:
  for +s: String
  for +c: Char
  for +r: String
  for +e: {D1.avoids(s, c) == True{} : Bool}
  {String.split(String.append(s, SCon{c, r}), c) == s <> String.split(r, c)
    : List<&2, String>}

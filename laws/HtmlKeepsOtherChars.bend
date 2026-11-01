# Every other character is written as itself.
import Base
import ../src/html.bend as Html

# LAW: every other character is written as itself
law html_other:
  for +c: Char
  for e1: {False{} == Char.is_eq(c, '&') : Bool}
  for e2: {False{} == Char.is_eq(c, '<') : Bool}
  for e3: {False{} == Char.is_eq(c, '>') : Bool}
  for e4: {False{} == Char.is_eq(c, '"') : Bool}
  for e5: {False{} == Char.is_eq(c, '\'') : Bool}
  for rest: String
  {Html.one(c, rest) == SCon{c, rest} : String}

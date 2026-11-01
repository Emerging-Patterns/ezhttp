import Base
import ../src/http.bend as Http
import ./defs/CharacterAbsent.bend as D1

# LAW: the first piece of a line split on a space is the word before it
law first_is_first_word:
  for +w: String
  for r: String
  for +e: {D1.avoids(w, ' ') == True{} : Bool}
  {Http.first(String.split(String.append(w, SCon{' ', r}), ' ')) == w : String}

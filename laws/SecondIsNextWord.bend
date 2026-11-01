import Base
import ../src/http.bend as Http
import ./defs/CharacterAbsent.bend as D1

# LAW: the second piece is the first word of what follows (status code on
# `HTTP/1.1 200 OK`, RFC 9112 §4)
law second_is_next_word:
  for +w: String
  for r: String
  for +e: {D1.avoids(w, ' ') == True{} : Bool}
  {Http.second(String.split(String.append(w, SCon{' ', r}), ' '))
    == Http.first(String.split(r, ' ')) : String}

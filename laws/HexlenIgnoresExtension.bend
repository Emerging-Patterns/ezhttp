import Base
import ../src/http.bend as Http
import ./defs/CharacterAbsent.bend as D1

# LAW (RFC 9112 §7.1): a chunk-size extension after `;` does not change the
# length hexlen reads.
law hexlen_ignores_extension:
  for +s: String
  for ext: String
  for +e: {D1.avoids(s, ';') == True{} : Bool}
  {Http.hexlen(String.append(s, SCon{';', ext})) == Http.hexlen(s) : Nat}

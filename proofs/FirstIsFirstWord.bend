# proofs of laws/FirstIsFirstWord.bend
import Base
import ../src/http.bend as Http
import ../laws/FirstIsFirstWord.bend as Laws
import ../laws/SplitAtCharacter.bend as L1
import ./lemmas/BaseEqualities.bend as M1

def Laws.first_is_first_word(w, r, e):
  Equal.cong(List<&2, String>, String, ps => Http.first(ps),
    String.split(String.append(w, SCon{' ', r}), ' '),
    w <> String.split(r, ' '), L1.split_cut(w, ' ', r, e))

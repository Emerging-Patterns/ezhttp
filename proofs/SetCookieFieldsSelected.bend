# proofs of laws/SetCookieFieldsSelected.bend
import Base
import ../src/echo.bend as Echo
import ../laws/SetCookieFieldsSelected.bend as Laws

def Laws.ck_values_nil(_hs, e):
  %e : {Echo.values(_) == [] : List<&2, String>}
  {==}

def Laws.ck_values_hit(_name, value, t, e):
  %e : {Echo.values.put(value, Echo.values(t), _) == value <> Echo.values(t)
    : List<&2, String>}
  {==}

def Laws.ck_values_miss(_name, value, t, e):
  %e : {Echo.values.put(value, Echo.values(t), _) == Echo.values(t)
    : List<&2, String>}
  {==}

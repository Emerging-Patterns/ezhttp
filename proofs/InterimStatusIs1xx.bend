# proofs of laws/InterimStatusIs1xx.bend
import Base
import ../src/http.bend as Http
import ../laws/InterimStatusIs1xx.bend as Laws

def Laws.status_interim_some(_n):
  {==}

def Laws.status_interim_none(_m, e):
  %e : {Http.status.interim(_) == False{} : Bool}
  {==}

# A response's status is interim (RFC 9110 §15.2) exactly when it is 100 to
# 199; a status line that does not parse is not interim.
import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §15.2): a status is interim exactly when it is 100 to 199
law status_interim_some:
  for +n: U32
  {Http.status.interim(Some{n})
    == Bool.and(U32.is_le(100, n), U32.is_lt(n, 200)) : Bool}

# LAW: a status line that does not parse is not interim
law status_interim_none:
  for m: Maybe<&2, U32>
  for e: {None{} == m : Maybe<&2, U32>}
  {Http.status.interim(m) == False{} : Bool}

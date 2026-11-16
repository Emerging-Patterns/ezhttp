# proofs of laws/MethodsSafeAndIdempotent.bend
import Base
import ../src/http.bend as Http
import ../laws/MethodsSafeAndIdempotent.bend as Laws

def Laws.method_safe_is(_method):
  {==}

def Laws.method_idempotent_is(_method):
  {==}

def Laws.method_safe_idempotent(method, e):
  %Equal.sym(Bool, Http.method.safe(method), True{}, e)
    : {Bool.or(_, Bool.or(String.eq(method, "PUT"), String.eq(method, "DELETE")))
      == True{} : Bool}
  {==}

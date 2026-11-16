# Boolean facts the CORS proofs use
import Base

law and_false:
  for b: Bool
  {Bool.and(b, False{}) == False{} : Bool}

def and_false(b):
  match b:
    case False{}:
      {==}
    case True{}:
      {==}

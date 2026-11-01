# proofs of laws/OnlyGetFollows.bend
import Base
import ../laws/OnlyGetFollows.bend as Laws

def Laws.follows_get(follow):
  match follow:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.follows_other(_method, e, follow):
  match follow:
    case True{}:
      %e : {_ == False{} : Bool}
      {==}
    case False{}:
      {==}

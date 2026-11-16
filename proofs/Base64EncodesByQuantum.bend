# proofs of laws/Base64EncodesByQuantum.bend
import Base
import ../laws/Base64EncodesByQuantum.bend as Laws

def Laws.b64_three(_a, _b, _c, _s):
  {==}

def Laws.b64_two(_a, _b):
  {==}

def Laws.b64_one(_a):
  {==}

# a non-empty input starts a quantum, and every quantum writes characters
def Laws.b64_empty(s):
  match s:
    case SNil{}:
      {==}
    case SCon{a, SNil{}}:
      {==}
    case SCon{a, SCon{b, SNil{}}}:
      {==}
    case SCon{a, SCon{b, SCon{c, t}}}:
      {==}

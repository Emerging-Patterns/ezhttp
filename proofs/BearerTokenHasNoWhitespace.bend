# proofs of laws/BearerTokenHasNoWhitespace.bend
import Base
import ../src/http.bend as Http
import ../laws/BearerTokenHasNoWhitespace.bend as Laws
import ./lemmas/BaseEqualities.bend as M1

# LAW: a step whose rest rejects rejects
law step_false:
  for x: Bool
  for r: Bool
  for ih: {r == False{} : Bool}
  {Http.token.ok.step(x, _u => r) == False{} : Bool}

# a step whose rest rejects rejects, whatever the head
def step_false(x, _r, ih):
  match x:
    case True{}:
      {==}
    case False{}:
      ih

# LAW: a step on a non-whitespace head is its rest
law step_at:
  for x: Bool
  for r: Bool
  for e: {x == False{} : Bool}
  {Http.token.ok.step(x, _u => r) == r : Bool}

# the step on a head that is not whitespace is its rest
def step_at(x, r, e):
  match x:
    case True{}:
      M1.eq.bit.absurd(&2, {Http.token.ok.step(True{}, _u => r) == r : Bool},
        Equal.sym(Bool, True{}, False{}, e))
    case False{}:
      {==}

def Laws.token_ok_space(a, c, b, e):
  match a:
    case SNil{}:
      %Equal.sym(Bool, Char.is_space(c), True{}, e)
        : {Http.token.ok.step(_, _u => Http.token.ok(b)) == False{} : Bool}
      {==}
    case SCon{h, +t}:
      step_false(Char.is_space(h), Http.token.ok(t ++ SCon{c, b}),
        Laws.token_ok_space(t, c, b, e))

def Laws.token_ok_plain(c, t, e):
  step_at(Char.is_space(c), Http.token.ok(t), e)

# a string against itself, for the cookie path rules: it starts with itself
# and orders equal to itself
import Base
import ./BaseEqualities.bend as M1

law order_self:
  for +s: String
  {String.order.go(s, s, EQ{}) == EQ{} : Cmp}

def order_self(s):
  match s:
    case SNil{}:
      {==}
    case SCon{Chr{+x}, +t}:
      %Equal.sym(Cmp, U32.cmp(x, x), EQ{}, M1.eq.u32_cmp_self(x))
        : {String.order.go(t, t, _) == EQ{} : Cmp}
      order_self(t)

law starts_self:
  for +s: String
  {String.starts_with.go(s, s) == True{} : Bool}

def starts_self(s):
  match s:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      %Equal.sym(Bool, Char.is_eq(h, h), True{}, M1.eq.char_eq_self(h))
        : {String.starts_with.go.if(t, t, _) == True{} : Bool}
      starts_self(t)

# order and subtraction on natural numbers, and taking all of a text
import Base
import ../../src/http.bend as Http

law lt_zero:
  for n: Nat
  {Nat.is_lt(n, 0n) == False{} : Bool}

def lt_zero(n):
  match n:
    case 0n:
      {==}
    case 1n+p:
      {==}

law lt_add:
  for a: Nat
  for +b: Nat
  {Nat.is_lt(Nat.add(a, b), a) == False{} : Bool}

def lt_add(a, b):
  match a:
    case 0n:
      lt_zero(b)
    case 1n+p:
      lt_add(p, b)

law lt_self:
  for n: Nat
  {Nat.is_lt(n, n) == False{} : Bool}

def lt_self(n):
  match n:
    case 0n:
      {==}
    case 1n+p:
      lt_self(p)

law sub_zero:
  for n: Nat
  {Nat.sub(n, 0n) == n : Nat}

def sub_zero(n):
  match n:
    case 0n:
      {==}
    case 1n+p:
      {==}

law sub_add:
  for a: Nat
  for +b: Nat
  {Nat.sub(Nat.add(a, b), a) == b : Nat}

def sub_add(a, b):
  match a:
    case 0n:
      sub_zero(b)
    case 1n+p:
      sub_add(p, b)

law take_all:
  for +s: String
  {Http.octs.take(s, Http.octs.len(s)) == s : String}

def take_all(s):
  match s:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      Equal.trans(String,
        Http.octs.take(SCon{h, t}, Http.octs.len(SCon{h, t})),
        SCon{h, Http.octs.take(t, Nat.sub(
          Nat.add(Http.octs.width(Char.to_u32(h)), Http.octs.len(t)),
          Http.octs.width(Char.to_u32(h))))},
        SCon{h, t},
        Equal.cong(Bool, String,
          b => Http.octs.take.step(b, h, _u => Http.octs.take(t, Nat.sub(
            Nat.add(Http.octs.width(Char.to_u32(h)), Http.octs.len(t)),
            Http.octs.width(Char.to_u32(h))))),
          Nat.is_lt(Nat.add(Http.octs.width(Char.to_u32(h)), Http.octs.len(t)),
            Http.octs.width(Char.to_u32(h))),
          False{},
          lt_add(Http.octs.width(Char.to_u32(h)), Http.octs.len(t))),
        Equal.trans(String,
          SCon{h, Http.octs.take(t, Nat.sub(
            Nat.add(Http.octs.width(Char.to_u32(h)), Http.octs.len(t)),
            Http.octs.width(Char.to_u32(h))))},
          SCon{h, Http.octs.take(t, Http.octs.len(t))},
          SCon{h, t},
          Equal.cong(Nat, String, m => SCon{h, Http.octs.take(t, m)},
            Nat.sub(Nat.add(Http.octs.width(Char.to_u32(h)), Http.octs.len(t)),
              Http.octs.width(Char.to_u32(h))),
            Http.octs.len(t),
            sub_add(Http.octs.width(Char.to_u32(h)), Http.octs.len(t))),
          Equal.cong(String, String, x => SCon{h, x},
            Http.octs.take(t, Http.octs.len(t)), t, take_all(t))))

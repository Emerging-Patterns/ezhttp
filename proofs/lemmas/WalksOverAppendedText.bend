# text walks (cut, drop, skip, the chunk walk) over appended text
import Base
import ../../src/http.bend as Http
import ../../laws/ReadStateMatchesWholeText.bend as L1
import ./BaseEqualities.bend as M1
import ./DropNothing.bend as M2
import ./NatOrder.bend as M3

# --- the chunk walk, read by read ---

# what a skip leaves: the text after the octets it walked off
def sk.text(s: Http.Skip) -> String:
  match s:
    case Http.Short{o}:
      ""
    case Http.Over{l, r}:
      r

# whether a text is at least the skipped octets and j more
def sk.has(s: Http.Skip, +j: Nat) -> Bool:
  match s:
    case Http.Short{o}:
      Http.octs.has("", Nat.add(o, j))
    case Http.Over{l, r}:
      Http.octs.has(r, Nat.add(l, j))

# the text after the skipped octets and j more
def sk.drop(s: Http.Skip, +j: Nat) -> String:
  match s:
    case Http.Short{o}:
      ""
    case Http.Over{l, r}:
      Http.octs.drop(r, Nat.add(l, j))

# a skip carried on into more text
def sk.then(s: Http.Skip, b: String) -> Http.Skip:
  match s:
    case Http.Short{o}:
      Http.octs.skip(b, o)
    case Http.Over{l, r}:
      Http.Over{l, r ++ b}

law width_pos:
  for +u: U32
  {Nat.is_lt(0n, Http.octs.width(u)) == True{} : Bool}

def width_pos(_u):
  {==}

law has_zero:
  for s: String
  {Http.octs.has(s, 0n) == True{} : Bool}

def has_zero(s):
  match s:
    case SNil{}:
      {==}
    case SCon{+h, t}:
      +w = Http.octs.width(Char.to_u32(h))
      %Equal.sym(Bool, Nat.is_lt(0n, w), True{}, width_pos(Char.to_u32(h)))
        : {Http.octs.has.step(_, _u => Http.octs.has(t, Nat.sub(0n, w)))
          == True{} : Bool}
      {==}

law drop_zero8:
  for s: String
  {Http.octs.drop(s, 0n) == s : String}

def drop_zero8(s):
  match s:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      +w = Http.octs.width(Char.to_u32(h))
      %Equal.sym(Bool, Nat.is_lt(0n, w), True{}, width_pos(Char.to_u32(h)))
        : {Http.octs.drop.step(_, h, t, _u => Http.octs.drop(t, Nat.sub(0n, w)))
          == SCon{h, t} : String}
      {==}

law lt_grow:
  for n: Nat
  for w: Nat
  for +j: Nat
  for e: {False{} == Nat.is_lt(n, w) : Bool}
  {Nat.is_lt(Nat.add(n, j), w) == False{} : Bool}

def lt_grow(n, w, j, e):
  match n w:
    case 0n 0n:
      M3.lt_zero(j)
    case 1n+q 0n:
      {==}
    case 0n 1n+p:
      M1.eq.bit.absurd(&2, {Nat.is_lt(Nat.add(0n, j), 1n+p) == False{} : Bool}, e)
    case 1n+q 1n+p:
      lt_grow(q, p, j, e)

law sub_grow:
  for n: Nat
  for w: Nat
  for +j: Nat
  for e: {False{} == Nat.is_lt(n, w) : Bool}
  {Nat.sub(Nat.add(n, j), w) == Nat.add(Nat.sub(n, w), j) : Nat}

def sub_grow(n, w, j, e):
  match n w:
    case 0n 0n:
      M3.sub_zero(j)
    case 1n+q 0n:
      {==}
    case 0n 1n+p:
      M1.eq.bit.absurd(&2, {Nat.sub(Nat.add(0n, j), 1n+p)
        == Nat.add(Nat.sub(0n, 1n+p), j) : Nat}, e)
    case 1n+q 1n+p:
      sub_grow(q, p, j, e)

law skip_text.arm:
  for -h: Char
  for -t: String
  for -n: Nat
  for -w: Nat
  for b: Bool
  for ih: {Http.octs.drop(t, Nat.sub(n, w))
    == sk.text(Http.octs.skip(t, Nat.sub(n, w))) : String}
  {Http.octs.drop.step(b, h, t, _u => Http.octs.drop(t, Nat.sub(n, w)))
    == sk.text(Http.octs.skip.step(b, n, h, t,
      _u => Http.octs.skip(t, Nat.sub(n, w)))) : String}

def skip_text.arm(_h, _t, _n, _w, b, ih):
  match b:
    case True{}:
      {==}
    case False{}:
      ih

law skip_text:
  for s: String
  for +n: Nat
  {Http.octs.drop(s, n) == sk.text(Http.octs.skip(s, n)) : String}

def skip_text(s, n):
  match s:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      +w = Http.octs.width(Char.to_u32(h))
      skip_text.arm(h, t, n, w, Nat.is_lt(n, w), skip_text(t, Nat.sub(n, w)))

law skip_has.arm:
  for +h: Char
  for +t: String
  for +n: Nat
  for +j: Nat
  for b: Bool
  for +e: {b == Nat.is_lt(n, Http.octs.width(Char.to_u32(h))) : Bool}
  for ih: {Http.octs.has(t, Nat.add(Nat.sub(n, Http.octs.width(Char.to_u32(h))), j))
    == sk.has(Http.octs.skip(t, Nat.sub(n, Http.octs.width(Char.to_u32(h)))), j) : Bool}
  {Http.octs.has(SCon{h, t}, Nat.add(n, j))
    == sk.has(Http.octs.skip.step(b, n, h, t,
      _u => Http.octs.skip(t, Nat.sub(n, Http.octs.width(Char.to_u32(h))))), j) : Bool}

def skip_has.arm(h, t, n, j, b, e, ih):
  match b:
    case True{}:
      {==}
    case False{}:
      %Equal.sym(Bool, Nat.is_lt(Nat.add(n, j), Http.octs.width(Char.to_u32(h))), False{}, lt_grow(n,
          Http.octs.width(Char.to_u32(h)), j, e))
        : {Http.octs.has.step(_,
          _u => Http.octs.has(t, Nat.sub(Nat.add(n, j), Http.octs.width(Char.to_u32(h)))))
          == sk.has(Http.octs.skip(t, Nat.sub(n, Http.octs.width(Char.to_u32(h)))), j) : Bool}
      %Equal.sym(Nat, Nat.sub(Nat.add(n, j), Http.octs.width(Char.to_u32(h))), Nat.add(Nat.sub(n,
          Http.octs.width(Char.to_u32(h))), j),
        sub_grow(n, Http.octs.width(Char.to_u32(h)), j, e))
        : {Http.octs.has(t, _)
          == sk.has(Http.octs.skip(t, Nat.sub(n, Http.octs.width(Char.to_u32(h)))), j) : Bool}
      ih

law skip_has:
  for s: String
  for +n: Nat
  for +j: Nat
  {Http.octs.has(s, Nat.add(n, j)) == sk.has(Http.octs.skip(s, n), j) : Bool}

def skip_has(s, n, j):
  match s:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      skip_has.arm(h, t, n, j, Nat.is_lt(n, Http.octs.width(Char.to_u32(h))), {==},
        skip_has(t, Nat.sub(n, Http.octs.width(Char.to_u32(h))), j))

law skip_drop.arm:
  for +h: Char
  for +t: String
  for +n: Nat
  for +j: Nat
  for b: Bool
  for +e: {b == Nat.is_lt(n, Http.octs.width(Char.to_u32(h))) : Bool}
  for ih: {Http.octs.drop(t, Nat.add(Nat.sub(n, Http.octs.width(Char.to_u32(h))), j))
    == sk.drop(Http.octs.skip(t, Nat.sub(n, Http.octs.width(Char.to_u32(h)))), j) : String}
  {Http.octs.drop(SCon{h, t}, Nat.add(n, j))
    == sk.drop(Http.octs.skip.step(b, n, h, t,
      _u => Http.octs.skip(t, Nat.sub(n, Http.octs.width(Char.to_u32(h))))), j) : String}

def skip_drop.arm(h, t, n, j, b, e, ih):
  match b:
    case True{}:
      {==}
    case False{}:
      %Equal.sym(Bool, Nat.is_lt(Nat.add(n, j), Http.octs.width(Char.to_u32(h))), False{}, lt_grow(n,
          Http.octs.width(Char.to_u32(h)), j, e))
        : {Http.octs.drop.step(_, h, t,
          _u => Http.octs.drop(t, Nat.sub(Nat.add(n, j), Http.octs.width(Char.to_u32(h)))))
          == sk.drop(Http.octs.skip(t, Nat.sub(n, Http.octs.width(Char.to_u32(h)))), j) : String}
      %Equal.sym(Nat, Nat.sub(Nat.add(n, j), Http.octs.width(Char.to_u32(h))), Nat.add(Nat.sub(n,
          Http.octs.width(Char.to_u32(h))), j),
        sub_grow(n, Http.octs.width(Char.to_u32(h)), j, e))
        : {Http.octs.drop(t, _)
          == sk.drop(Http.octs.skip(t, Nat.sub(n, Http.octs.width(Char.to_u32(h)))), j) : String}
      ih

law skip_drop:
  for s: String
  for +n: Nat
  for +j: Nat
  {Http.octs.drop(s, Nat.add(n, j)) == sk.drop(Http.octs.skip(s, n), j)
    : String}

def skip_drop(s, n, j):
  match s:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      skip_drop.arm(h, t, n, j, Nat.is_lt(n, Http.octs.width(Char.to_u32(h))), {==},
        skip_drop(t, Nat.sub(n, Http.octs.width(Char.to_u32(h))), j))

law skip_app.arm:
  for +h: Char
  for +t: String
  for +b: String
  for +n: Nat
  for c: Bool
  for ih: {Http.octs.skip(t ++ b, Nat.sub(n, Http.octs.width(Char.to_u32(h))))
    == sk.then(Http.octs.skip(t, Nat.sub(n, Http.octs.width(Char.to_u32(h)))), b) : Http.Skip}
  {Http.octs.skip.step(c, n, h, t ++ b,
    _u => Http.octs.skip(t ++ b, Nat.sub(n, Http.octs.width(Char.to_u32(h)))))
    == sk.then(Http.octs.skip.step(c, n, h, t,
      _u => Http.octs.skip(t, Nat.sub(n, Http.octs.width(Char.to_u32(h))))), b) : Http.Skip}

def skip_app.arm(_h, _t, _b, _n, c, ih):
  match c:
    case True{}:
      {==}
    case False{}:
      ih

law skip_app:
  for s: String
  for +b: String
  for +n: Nat
  {Http.octs.skip(s ++ b, n) == sk.then(Http.octs.skip(s, n), b) : Http.Skip}

def skip_app(s, b, n):
  match s:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      skip_app.arm(h, t, b, n, Nat.is_lt(n, Http.octs.width(Char.to_u32(h))), skip_app(t, b, Nat.sub(n,
          Http.octs.width(Char.to_u32(h)))))

law has_app.arm:
  for +h: Char
  for +t: String
  for +b: String
  for +k: Nat
  for c: Bool
  for e: {True{} == Http.octs.has.step(c, _u => Http.octs.has(t, Nat.sub(k, Http.octs.width(Char.to_u32(h)))))
    : Bool}
  for ih: @e2: {True{} == Http.octs.has(t, Nat.sub(k, Http.octs.width(Char.to_u32(h)))) : Bool} ->
    {Http.octs.has(t ++ b, Nat.sub(k, Http.octs.width(Char.to_u32(h)))) == True{} : Bool}
  {Http.octs.has.step(c, _u => Http.octs.has(t ++ b, Nat.sub(k, Http.octs.width(Char.to_u32(h)))))
    == True{} : Bool}

def has_app.arm(_h, _t, _b, _k, c, e, ih):
  match c:
    case True{}:
      {==}
    case False{}:
      ih(e)

law has_app:
  for s: String
  for +b: String
  for +k: Nat
  for e: {True{} == Http.octs.has(s, k) : Bool}
  {Http.octs.has(s ++ b, k) == True{} : Bool}

def has_app(s, b, k, e):
  match s k:
    case SNil{} 0n:
      has_zero(b)
    case SNil{} 1n+p:
      M1.eq.bit.absurd(&2, {Http.octs.has(b, 1n+p) == True{} : Bool},
        Equal.sym(Bool, True{}, False{}, e))
    case SCon{+h, +t} _:
      has_app.arm(h, t, b, k, Nat.is_lt(k, Http.octs.width(Char.to_u32(h))), e,
        e2 => has_app(t, b, Nat.sub(k, Http.octs.width(Char.to_u32(h))), e2))

law drop_app.arm:
  for +h: Char
  for +t: String
  for +b: String
  for +k: Nat
  for c: Bool
  for e: {True{} == Http.octs.has.step(c, _u => Http.octs.has(t, Nat.sub(k, Http.octs.width(Char.to_u32(h)))))
    : Bool}
  for ih: @e2: {True{} == Http.octs.has(t, Nat.sub(k, Http.octs.width(Char.to_u32(h)))) : Bool} ->
    {Http.octs.drop(t ++ b, Nat.sub(k, Http.octs.width(Char.to_u32(h)))) == Http.octs.drop(t, Nat.sub(k,
        Http.octs.width(Char.to_u32(h)))) ++ b
      : String}
  {Http.octs.drop.step(c, h, t ++ b, _u => Http.octs.drop(t ++ b, Nat.sub(k, Http.octs.width(Char.to_u32(h)))))
    == Http.octs.drop.step(c, h, t, _u => Http.octs.drop(t, Nat.sub(k, Http.octs.width(Char.to_u32(h))))) ++ b
    : String}

def drop_app.arm(_h, _t, _b, _k, c, e, ih):
  match c:
    case True{}:
      {==}
    case False{}:
      ih(e)

law drop_app:
  for s: String
  for +b: String
  for +k: Nat
  for e: {True{} == Http.octs.has(s, k) : Bool}
  {Http.octs.drop(s ++ b, k) == Http.octs.drop(s, k) ++ b : String}

def drop_app(s, b, k, e):
  match s k:
    case SNil{} 0n:
      drop_zero8(b)
    case SNil{} 1n+p:
      M1.eq.bit.absurd(&2, {Http.octs.drop(b, 1n+p) == b : String},
        Equal.sym(Bool, True{}, False{}, e))
    case SCon{+h, +t} _:
      drop_app.arm(h, t, b, k, Nat.is_lt(k, Http.octs.width(Char.to_u32(h))), e,
        e2 => drop_app(t, b, Nat.sub(k, Http.octs.width(Char.to_u32(h))), e2))

law sw_app.arm:
  for +xt: String
  for +yt: String
  for +b: String
  for c: Bool
  for e: {True{} == String.starts_with.go.if(yt, xt, c) : Bool}
  for ih: @e2: {True{} == String.starts_with.go(yt, xt) : Bool} ->
    {String.starts_with.go(yt, xt ++ b) == True{} : Bool}
  {String.starts_with.go.if(yt, xt ++ b, c) == True{} : Bool}

def sw_app.arm(_xt, _yt, _b, c, e, ih):
  match c:
    case True{}:
      ih(e)
    case False{}:
      M1.eq.bit.absurd(&2, {False{} == True{} : Bool},
        Equal.sym(Bool, True{}, False{}, e))

law sw_app:
  for s: String
  for p: String
  for +b: String
  for e: {True{} == String.starts_with(s, p) : Bool}
  {String.starts_with(s ++ b, p) == True{} : Bool}

def sw_app(s, p, b, e):
  match s p:
    case _ SNil{}:
      {==}
    case SNil{} SCon{y, yt}:
      M1.eq.bit.absurd(&2, {String.starts_with.go(SCon{y, yt}, b) == True{} : Bool},
        Equal.sym(Bool, True{}, False{}, e))
    case SCon{+x, +xt} SCon{+y, +yt}:
      sw_app.arm(xt, yt, b, Char.is_eq(x, y), e, e2 => sw_app(xt, yt, b, e2))

law contains_nil:
  for s: String
  {String.contains(s, "") == True{} : Bool}

def contains_nil(s):
  match s:
    case SNil{}:
      {==}
    case SCon{h, t}:
      {==}

law contains_if:
  for +t: String
  for +p: String
  for c: Bool
  for e: {String.contains(t, p) == True{} : Bool}
  {String.contains.if(t, p, c) == True{} : Bool}

def contains_if(_t, _p, c, e):
  match c:
    case True{}:
      {==}
    case False{}:
      e

law contains_app.arm:
  for +h: Char
  for +t: String
  for +p: String
  for +b: String
  for c: Bool
  for +ec: {c == String.starts_with(SCon{h, t}, p) : Bool}
  for e: {True{} == String.contains.if(t, p, c) : Bool}
  for ih: @e2: {True{} == String.contains(t, p) : Bool} ->
    {String.contains(t ++ b, p) == True{} : Bool}
  {String.contains.if(t ++ b, p, String.starts_with(SCon{h, t ++ b}, p))
    == True{} : Bool}

def contains_app.arm(h, t, p, b, c, ec, e, ih):
  match c:
    case True{}:
      %Equal.sym(Bool, String.starts_with(SCon{h, t} ++ b, p), True{},
        sw_app(SCon{h, t}, p, b, ec))
        : {String.contains.if(t ++ b, p, _) == True{} : Bool}
      {==}
    case False{}:
      contains_if(t ++ b, p, String.starts_with(SCon{h, t ++ b}, p), ih(e))

law contains_app:
  for s: String
  for +p: String
  for +b: String
  for e: {True{} == String.contains(s, p) : Bool}
  {String.contains(s ++ b, p) == True{} : Bool}

def contains_app(s, p, b, e):
  match s p:
    case SNil{} SNil{}:
      contains_nil(b)
    case SNil{} SCon{y, yt}:
      M1.eq.bit.absurd(&2, {String.contains(b, SCon{y, yt}) == True{} : Bool},
        Equal.sym(Bool, True{}, False{}, e))
    case SCon{+h, +t} _:
      contains_app.arm(h, t, p, b, String.starts_with(SCon{h, t}, p), {==}, e,
        e2 => contains_app(t, p, b, e2))

law or_true:
  for x: Bool
  {Bool.or(x, True{}) == True{} : Bool}

def or_true(x):
  match x:
    case True{}:
      {==}
    case False{}:
      {==}

law or_app:
  for x: Bool
  for y: Bool
  for +x2: Bool
  for +y2: Bool
  for e: {True{} == Bool.or(x, y) : Bool}
  for fx: @ex: {True{} == x : Bool} -> {x2 == True{} : Bool}
  for fy: @ey: {True{} == y : Bool} -> {y2 == True{} : Bool}
  {Bool.or(x2, y2) == True{} : Bool}

def or_app(x, _y, x2, y2, e, fx, fy):
  match x:
    case True{}:
      %Equal.sym(Bool, x2, True{}, fx({==})) : {Bool.or(_, y2) == True{} : Bool}
      {==}
    case False{}:
      %Equal.sym(Bool, y2, True{}, fy(e))
        : {Bool.or(x2, _) == True{} : Bool}
      or_true(x2)

law trailer_app:
  for +after: String
  for +b: String
  for e: {True{} == Http.chunks.trailer(after) : Bool}
  {Http.chunks.trailer(after ++ b) == True{} : Bool}

def trailer_app(after, b, e):
  or_app(String.starts_with(after, "\r\n"), String.contains(after, "\r\n\r\n"),
    String.starts_with(after ++ b, "\r\n"),
    String.contains(after ++ b, "\r\n\r\n"), e,
    ex => sw_app(after, "\r\n", b, ex),
    ey => contains_app(after, "\r\n\r\n", b, ey))

# whether a divide found its pattern
def cut.is(c: Http.Cut) -> Bool:
  match c:
    case Http.NoCut{}:
      False{}
    case Http.Cut{x, y}:
      True{}

# a divide's second half with more text after it
def cut.app(c: Http.Cut, b: String) -> Http.Cut:
  match c:
    case Http.NoCut{}:
      Http.NoCut{}
    case Http.Cut{x, y}:
      Http.Cut{x, y ++ b}

law cut_is_push:
  for h: Char
  for r: Http.Cut
  {cut.is(Http.divide.push(h, r)) == cut.is(r) : Bool}

def cut_is_push(_h, r):
  match r:
    case Http.NoCut{}:
      {==}
    case Http.Cut{x, y}:
      {==}

law cut_app_push:
  for h: Char
  for r: Http.Cut
  for +b: String
  {cut.app(Http.divide.push(h, r), b) == Http.divide.push(h, cut.app(r, b))
    : Http.Cut}

def cut_app_push(_h, r, _b):
  match r:
    case Http.NoCut{}:
      {==}
    case Http.Cut{x, y}:
      {==}

law len_app:
  for a: String
  for +b: String
  {String.length(a ++ b) == Nat.add(String.length(a), String.length(b)) : Nat}

def len_app(a, b):
  match a:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      Equal.cong(Nat, Nat, x => 1n+x, String.length(t ++ b),
        Nat.add(String.length(t), String.length(b)), len_app(t, b))

law lt_succ:
  for l: Nat
  for p: Nat
  for e: {False{} == Nat.is_lt(l, p) : Bool}
  {Nat.is_lt(1n+l, p) == False{} : Bool}

def lt_succ(l, p, e):
  match l p:
    case _ 0n:
      {==}
    case 0n 1n+q:
      M1.eq.bit.absurd(&2, {Nat.is_lt(1n, 1n+q) == False{} : Bool}, e)
    case 1n+k 1n+q:
      lt_succ(k, q, e)

law sw_len.arm:
  for +xt: String
  for +yt: String
  for c: Bool
  for e: {True{} == String.starts_with.go.if(yt, xt, c) : Bool}
  for ih: @e2: {True{} == String.starts_with.go(yt, xt) : Bool} ->
    {Nat.is_lt(String.length(xt), String.length(yt)) == False{} : Bool}
  {Nat.is_lt(String.length(xt), String.length(yt)) == False{} : Bool}

def sw_len.arm(xt, yt, c, e, ih):
  match c:
    case True{}:
      ih(e)
    case False{}:
      M1.eq.bit.absurd(&2, {Nat.is_lt(String.length(xt), String.length(yt))
        == False{} : Bool}, Equal.sym(Bool, True{}, False{}, e))

law sw_len:
  for s: String
  for p: String
  for e: {True{} == String.starts_with(s, p) : Bool}
  {Nat.is_lt(String.length(s), String.length(p)) == False{} : Bool}

def sw_len(s, p, e):
  match s p:
    case _ SNil{}:
      M3.lt_zero(String.length(s))
    case SNil{} SCon{y, yt}:
      M1.eq.bit.absurd(&2, {Nat.is_lt(0n, 1n+String.length(yt)) == False{} : Bool},
        Equal.sym(Bool, True{}, False{}, e))
    case SCon{+x, +xt} SCon{+y, +yt}:
      sw_len.arm(xt, yt, Char.is_eq(x, y), e, e2 => sw_len(xt, yt, e2))

law sw_long.arm:
  for +xt: String
  for +yt: String
  for +b: String
  for c: Bool
  for ih: {String.starts_with.go(yt, xt ++ b) == String.starts_with.go(yt, xt)
    : Bool}
  {String.starts_with.go.if(yt, xt ++ b, c)
    == String.starts_with.go.if(yt, xt, c) : Bool}

def sw_long.arm(_xt, _yt, _b, c, ih):
  match c:
    case True{}:
      ih
    case False{}:
      {==}

law sw_long:
  for s: String
  for p: String
  for +b: String
  for e: {False{} == Nat.is_lt(String.length(s), String.length(p)) : Bool}
  {String.starts_with(s ++ b, p) == String.starts_with(s, p) : Bool}

def sw_long(s, p, b, e):
  match s p:
    case _ SNil{}:
      {==}
    case SNil{} SCon{y, yt}:
      M1.eq.bit.absurd(&2, {String.starts_with(b, SCon{y, yt})
        == String.starts_with(SNil{}, SCon{y, yt}) : Bool}, e)
    case SCon{+x, +xt} SCon{+y, +yt}:
      sw_long.arm(xt, yt, b, Char.is_eq(x, y), sw_long(xt, yt, b, e))

law sdrop_app.arm:
  for +xt: String
  for +yt: String
  for +b: String
  for c: Bool
  for e: {True{} == String.starts_with.go.if(yt, xt, c) : Bool}
  for ih: @e2: {True{} == String.starts_with.go(yt, xt) : Bool} ->
    {String.drop(xt ++ b, String.length(yt))
      == String.drop(xt, String.length(yt)) ++ b : String}
  {String.drop(xt ++ b, String.length(yt))
    == String.drop(xt, String.length(yt)) ++ b : String}

def sdrop_app.arm(xt, yt, b, c, e, ih):
  match c:
    case True{}:
      ih(e)
    case False{}:
      M1.eq.bit.absurd(&2, {String.drop(xt ++ b, String.length(yt))
        == String.drop(xt, String.length(yt)) ++ b : String},
        Equal.sym(Bool, True{}, False{}, e))

law sdrop_app:
  for s: String
  for p: String
  for +b: String
  for e: {True{} == String.starts_with(s, p) : Bool}
  {String.drop(s ++ b, String.length(p)) == String.drop(s, String.length(p)) ++ b
    : String}

def sdrop_app(s, p, b, e):
  match s p:
    case SNil{} SNil{}:
      M2.eq.drop_zero(b)
    case SCon{x, xt} SNil{}:
      {==}
    case SNil{} SCon{y, yt}:
      M1.eq.bit.absurd(&2, {String.drop(b, 1n+String.length(yt))
        == String.drop(SNil{}, 1n+String.length(yt)) ++ b : String},
        Equal.sym(Bool, True{}, False{}, e))
    case SCon{+x, +xt} SCon{+y, +yt}:
      sdrop_app.arm(xt, yt, b, Char.is_eq(x, y), e, e2 => sdrop_app(xt, yt, b, e2))

law cut_len.arm:
  for +h: Char
  for +t: String
  for +p: String
  for c: Bool
  for +ec: {c == String.starts_with(SCon{h, t}, p) : Bool}
  for e: {True{} == cut.is(Http.divide.step(c, h, t, String.length(p),
    _u => Http.divide.go(t, p, String.length(p)))) : Bool}
  for ih: @e2: {True{} == cut.is(Http.divide.go(t, p, String.length(p))) : Bool} ->
    {Nat.is_lt(String.length(t), String.length(p)) == False{} : Bool}
  {Nat.is_lt(1n+String.length(t), String.length(p)) == False{} : Bool}

def cut_len.arm(h, t, p, c, ec, e, ih):
  match c:
    case True{}:
      sw_len(SCon{h, t}, p, ec)
    case False{}:
      +ih2 = ih(Equal.trans(Bool, True{},
        cut.is(Http.divide.push(h, Http.divide.go(t, p, String.length(p)))),
        cut.is(Http.divide.go(t, p, String.length(p))), e,
        cut_is_push(h, Http.divide.go(t, p, String.length(p)))))
      lt_succ(String.length(t), String.length(p),
        Equal.sym(Bool, Nat.is_lt(String.length(t), String.length(p)), False{},
          ih2))

law cut_len:
  for s: String
  for +p: String
  for e: {True{} == cut.is(Http.divide.go(s, p, String.length(p))) : Bool}
  {Nat.is_lt(String.length(s), String.length(p)) == False{} : Bool}

def cut_len(s, p, e):
  match s:
    case SNil{}:
      M1.eq.bit.absurd(&2, {Nat.is_lt(0n, String.length(p)) == False{} : Bool},
        Equal.sym(Bool, True{}, False{}, e))
    case SCon{+h, +t}:
      cut_len.arm(h, t, p, String.starts_with(SCon{h, t}, p), {==}, e,
        e2 => cut_len(t, p, e2))

law divide_app.arm:
  for +h: Char
  for +t: String
  for +p: String
  for +b: String
  for c: Bool
  for +ec: {c == String.starts_with(SCon{h, t}, p) : Bool}
  for e: {True{} == cut.is(Http.divide.step(c, h, t, String.length(p),
    _u => Http.divide.go(t, p, String.length(p)))) : Bool}
  for ih: @e2: {True{} == cut.is(Http.divide.go(t, p, String.length(p))) : Bool} ->
    {Http.divide.go(t ++ b, p, String.length(p))
      == cut.app(Http.divide.go(t, p, String.length(p)), b) : Http.Cut}
  {Http.divide.go(SCon{h, t ++ b}, p, String.length(p))
    == cut.app(Http.divide.step(c, h, t, String.length(p),
      _u => Http.divide.go(t, p, String.length(p))), b) : Http.Cut}

def divide_app.arm(h, t, p, b, c, ec, e, ih):
  match c:
    case True{}:
      %Equal.sym(Bool, String.starts_with(SCon{h, t} ++ b, p), True{},
        sw_app(SCon{h, t}, p, b, ec))
        : {Http.divide.step(_, h, t ++ b, String.length(p),
          _u => Http.divide.go(t ++ b, p, String.length(p)))
          == Http.Cut{"", String.drop(SCon{h, t}, String.length(p)) ++ b}
          : Http.Cut}
      Equal.cong(String, Http.Cut, x => Http.Cut{"", x},
        String.drop(SCon{h, t} ++ b, String.length(p)),
        String.drop(SCon{h, t}, String.length(p)) ++ b,
        sdrop_app(SCon{h, t}, p, b, ec))
    case False{}:
      +e2 = Equal.trans(Bool, True{},
        cut.is(Http.divide.push(h, Http.divide.go(t, p, String.length(p)))),
        cut.is(Http.divide.go(t, p, String.length(p))), e,
        cut_is_push(h, Http.divide.go(t, p, String.length(p))))
      +long = lt_succ(String.length(t), String.length(p),
        Equal.sym(Bool, Nat.is_lt(String.length(t), String.length(p)), False{},
          cut_len(t, p, e2)))
      +same = Equal.trans(Bool, String.starts_with(SCon{h, t} ++ b, p),
        String.starts_with(SCon{h, t}, p), False{},
        sw_long(SCon{h, t}, p, b, Equal.sym(Bool,
          Nat.is_lt(1n+String.length(t), String.length(p)), False{}, long)),
        Equal.sym(Bool, False{}, String.starts_with(SCon{h, t}, p), ec))
      %Equal.sym(Bool, String.starts_with(SCon{h, t} ++ b, p), False{}, same)
        : {Http.divide.step(_, h, t ++ b, String.length(p),
          _u => Http.divide.go(t ++ b, p, String.length(p)))
          == cut.app(Http.divide.push(h, Http.divide.go(t, p, String.length(p))),
            b) : Http.Cut}
      Equal.trans(Http.Cut,
        Http.divide.push(h, Http.divide.go(t ++ b, p, String.length(p))),
        Http.divide.push(h, cut.app(Http.divide.go(t, p, String.length(p)), b)),
        cut.app(Http.divide.push(h, Http.divide.go(t, p, String.length(p))), b),
        Equal.cong(Http.Cut, Http.Cut, r => Http.divide.push(h, r),
          Http.divide.go(t ++ b, p, String.length(p)),
          cut.app(Http.divide.go(t, p, String.length(p)), b), ih(e2)),
        Equal.sym(Http.Cut,
          cut.app(Http.divide.push(h, Http.divide.go(t, p, String.length(p))), b),
          Http.divide.push(h, cut.app(Http.divide.go(t, p, String.length(p)), b)),
          cut_app_push(h, Http.divide.go(t, p, String.length(p)), b)))

law divide_app:
  for s: String
  for +p: String
  for +b: String
  for e: {True{} == cut.is(Http.divide.go(s, p, String.length(p))) : Bool}
  {Http.divide.go(s ++ b, p, String.length(p))
    == cut.app(Http.divide.go(s, p, String.length(p)), b) : Http.Cut}

def divide_app(s, p, b, e):
  match s:
    case SNil{}:
      M1.eq.bit.absurd(&2, {Http.divide.go(b, p, String.length(p))
        == cut.app(Http.NoCut{}, b) : Http.Cut},
        Equal.sym(Bool, True{}, False{}, e))
    case SCon{+h, +t}:
      divide_app.arm(h, t, p, b, String.starts_with(SCon{h, t}, p), {==}, e,
        e2 => divide_app(t, p, b, e2))

law lt0_add2:
  for o: Nat
  {Nat.is_lt(0n, Nat.add(o, 2n)) == True{} : Bool}

def lt0_add2(o):
  match o:
    case 0n:
      {==}
    case 1n+p:
      {==}

law walk_done.crlf:
  for +g: Nat
  for +l: Nat
  for +r: String
  for +after: String
  for +n: Nat
  for rd: Bool
  for +ed: {Http.octs.drop(after, Nat.add(n, 2n))
    == Http.octs.drop(r, Nat.add(l, 2n)) : String}
  for ih: @s: String ->
    {Http.walk.done(Http.walk(g, s)) == Http.chunks.ended(g, Http.divide(s, "\r\n"))
      : Bool}
  {Http.walk.done(Http.walk.crlf(g, l, r, rd, s => Http.walk(g, s)))
    == Http.chunks.ended.data(after, n, rd, cut => Http.chunks.ended(g, cut)) : Bool}

def walk_done.crlf(g, l, r, after, n, rd, ed, ih):
  match rd:
    case True{}:
      %Equal.sym(String, Http.octs.drop(after, Nat.add(n, 2n)),
        Http.octs.drop(r, Nat.add(l, 2n)), ed)
        : {Http.walk.done(Http.walk(g, Http.octs.drop(r, Nat.add(l, 2n))))
        == Http.chunks.ended(g, Http.divide(_, "\r\n")) : Bool}
      ih(Http.octs.drop(r, Nat.add(l, 2n)))
    case False{}:
      {==}

law walk_done.data.arm:
  for +g: Nat
  for +after: String
  for +n: Nat
  for sk: Http.Skip
  for +eh: {Http.octs.has(after, Nat.add(n, 2n)) == sk.has(sk, 2n) : Bool}
  for +et: {Http.octs.drop(after, n) == sk.text(sk) : String}
  for +ed: {Http.octs.drop(after, Nat.add(n, 2n)) == sk.drop(sk, 2n) : String}
  for ih: @s: String ->
    {Http.walk.done(Http.walk(g, s)) == Http.chunks.ended(g, Http.divide(s, "\r\n"))
      : Bool}
  {Http.walk.done(Http.walk.data(g, sk, s => Http.walk(g, s)))
    == Http.chunks.ended.data(after, n, Http.chunks.ready(after, n), cut => Http.chunks.ended(g, cut))
    : Bool}

def walk_done.data.arm(g, after, n, sk, eh, et, ed, ih):
  match sk:
    case Http.Short{+o}:
      +hf = Equal.trans(Bool, Http.octs.has(after, Nat.add(n, 2n)),
        Bool.not(Nat.is_lt(0n, Nat.add(o, 2n))), False{}, eh,
        Equal.cong(Bool, Bool, x => Bool.not(x), Nat.is_lt(0n, Nat.add(o, 2n)),
          True{}, lt0_add2(o)))
      %Equal.sym(Bool, Http.octs.has(after, Nat.add(n, 2n)), False{}, hf)
        : {False{} == Http.chunks.ended.data(after, n,
          Bool.and(_, String.starts_with(Http.octs.drop(after, n), "\r\n")),
          cut => Http.chunks.ended(g, cut)) : Bool}
      {==}
    case Http.Over{+l, +r}:
      %Equal.sym(Bool, Http.octs.has(after, Nat.add(n, 2n)),
        Http.octs.has(r, Nat.add(l, 2n)), eh)
        : {Http.walk.done(Http.walk.crlf(g, l, r, Bool.and(
          Http.octs.has(r, Nat.add(l, 2n)), String.starts_with(r, "\r\n")), s => Http.walk(g, s)))
          == Http.chunks.ended.data(after, n,
          Bool.and(_, String.starts_with(Http.octs.drop(after, n), "\r\n")),
          cut => Http.chunks.ended(g, cut)) : Bool}
      %Equal.sym(String, Http.octs.drop(after, n), r, et)
        : {Http.walk.done(Http.walk.crlf(g, l, r, Bool.and(
          Http.octs.has(r, Nat.add(l, 2n)), String.starts_with(r, "\r\n")), s => Http.walk(g, s)))
          == Http.chunks.ended.data(after, n,
          Bool.and(Http.octs.has(r, Nat.add(l, 2n)), String.starts_with(_, "\r\n")),
          cut => Http.chunks.ended(g, cut)) : Bool}
      walk_done.crlf(g, l, r, after, n, Bool.and(Http.octs.has(r, Nat.add(l, 2n)),
        String.starts_with(r, "\r\n")), ed, ih)

law walk_done.data:
  for +g: Nat
  for +after: String
  for +n: Nat
  for sk: Http.Skip
  for +esk: {sk == Http.octs.skip(after, n) : Http.Skip}
  for ih: @s: String ->
    {Http.walk.done(Http.walk(g, s)) == Http.chunks.ended(g, Http.divide(s, "\r\n"))
      : Bool}
  {Http.walk.done(Http.walk.data(g, sk, s => Http.walk(g, s)))
    == Http.chunks.ended.data(after, n, Http.chunks.ready(after, n), cut => Http.chunks.ended(g, cut))
    : Bool}

def walk_done.data(g, after, n, sk, esk, ih):
  +eh = Equal.trans(Bool, Http.octs.has(after, Nat.add(n, 2n)),
    sk.has(Http.octs.skip(after, n), 2n), sk.has(sk, 2n),
    skip_has(after, n, 2n),
    Equal.cong(Http.Skip, Bool, x => sk.has(x, 2n), Http.octs.skip(after, n), sk,
      Equal.sym(Http.Skip, sk, Http.octs.skip(after, n), esk)))
  +et = Equal.trans(String, Http.octs.drop(after, n),
    sk.text(Http.octs.skip(after, n)), sk.text(sk),
    skip_text(after, n),
    Equal.cong(Http.Skip, String, x => sk.text(x), Http.octs.skip(after, n), sk,
      Equal.sym(Http.Skip, sk, Http.octs.skip(after, n), esk)))
  +ed = Equal.trans(String, Http.octs.drop(after, Nat.add(n, 2n)),
    sk.drop(Http.octs.skip(after, n), 2n), sk.drop(sk, 2n),
    skip_drop(after, n, 2n),
    Equal.cong(Http.Skip, String, x => sk.drop(x, 2n), Http.octs.skip(after, n), sk,
      Equal.sym(Http.Skip, sk, Http.octs.skip(after, n), esk)))
  walk_done.data.arm(g, after, n, sk, eh, et, ed, ih)

law walk_done.trail:
  for g: Nat
  for rest: String
  for t: Bool
  {Http.walk.done(Http.walk.trail(g, rest, t)) == t : Bool}

def walk_done.trail(_g, _rest, t):
  match t:
    case True{}:
      {==}
    case False{}:
      {==}

law walk_done.size:
  for +g: Nat
  for rest: String
  for +after: String
  for +n: Nat
  for z: Bool
  for ih: @s: String ->
    {Http.walk.done(Http.walk(g, s)) == Http.chunks.ended(g, Http.divide(s, "\r\n"))
      : Bool}
  {Http.walk.done(Http.walk.size(g, rest, after, n, z, s => Http.walk(g, s)))
    == Http.chunks.ended.size(after, n, z, cut => Http.chunks.ended(g, cut)) : Bool}

def walk_done.size(g, rest, after, n, z, ih):
  match z:
    case True{}:
      walk_done.trail(g, rest, Http.chunks.trailer(after))
    case False{}:
      walk_done.data(g, after, n, Http.octs.skip(after, n), {==}, ih)

law walk_done.hex:
  for +g: Nat
  for rest: String
  for +before: String
  for +after: String
  for ok: Bool
  for ih: @s: String ->
    {Http.walk.done(Http.walk(g, s)) == Http.chunks.ended(g, Http.divide(s, "\r\n"))
      : Bool}
  {Http.walk.done(Http.walk.hex(g, rest, before, after, ok, s => Http.walk(g, s)))
    == Http.chunks.ended.hex(before, after, ok, cut => Http.chunks.ended(g, cut)) : Bool}

def walk_done.hex(g, rest, before, after, ok, ih):
  match ok:
    case False{}:
      {==}
    case True{}:
      walk_done.size(g, rest, after, Http.hexlen(before),
        Nat.is_eq(Http.hexlen(before), 0n), ih)

law walk_done.at:
  for +g: Nat
  for rest: String
  for c: Http.Cut
  for ih: @s: String ->
    {Http.walk.done(Http.walk(g, s)) == Http.chunks.ended(g, Http.divide(s, "\r\n"))
      : Bool}
  {Http.walk.done(Http.walk.at(g, rest, c, s => Http.walk(g, s)))
    == Http.chunks.ended.at(c, cut => Http.chunks.ended(g, cut)) : Bool}

def walk_done.at(g, rest, c, ih):
  match c:
    case Http.NoCut{}:
      {==}
    case Http.Cut{+before, +after}:
      walk_done.hex(g, rest, before, after,
        Http.hex.well(Http.chunks.token(before)), ih)

def L1.walk_done(f, rest):
  match f:
    case 0n:
      {==}
    case 1n+f2:
      +g = f2
      walk_done.at(g, rest, Http.divide(rest, "\r\n"),
        s => L1.walk_done(g, s))

law wm.ready:
  for +g: Nat
  for rest: String
  for +b: String
  for +l: Nat
  for +r: String
  for +erd: {Bool.and(Http.octs.has(r, Nat.add(l, 2n)),
    String.starts_with(r, "\r\n")) == True{} : Bool}
  for +s1: {Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b) == Http.walk.crlf(Nat.add(g,
      String.length(b)), l, r ++ b, Bool.and(
    Http.octs.has(r ++ b, Nat.add(l, 2n)), String.starts_with(r ++ b, "\r\n")), s => Http.walk(Nat.add(g,
        String.length(b)), s))
    : Http.Walk}
  for ih: @s: String ->
    {Http.walk(Nat.add(g, String.length(b)), s ++ b) == Http.walk.more(Http.walk(g, s), String.length(b), b)
      : Http.Walk}
  {Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b) == Http.walk.more(Http.walk(g, Http.octs.drop(r,
      Nat.add(l, 2n))), String.length(b), b)
    : Http.Walk}

def wm.ready(g, rest, b, l, r, erd, s1, ih):
  +eh = Equal.sym(Bool, Http.octs.has(r, Nat.add(l, 2n)), True{},
    M1.eq.and.left(Http.octs.has(r, Nat.add(l, 2n)), String.starts_with(r, "\r\n"), erd))
  +es = Equal.sym(Bool, String.starts_with(r, "\r\n"), True{},
    M1.eq.and.right(Http.octs.has(r, Nat.add(l, 2n)), String.starts_with(r, "\r\n"), erd))
  +h2 = has_app(r, b, Nat.add(l, 2n), eh)
  +s2 = sw_app(r, "\r\n", b, es)
  +rd2 = Equal.trans(Bool, Bool.and(Http.octs.has(r ++ b, Nat.add(l, 2n)),
      String.starts_with(r ++ b, "\r\n")),
    Bool.and(True{}, String.starts_with(r ++ b, "\r\n")), True{},
    Equal.cong(Bool, Bool, x => Bool.and(x, String.starts_with(r ++ b, "\r\n")),
      Http.octs.has(r ++ b, Nat.add(l, 2n)), True{}, h2), s2)
  Equal.trans(Http.Walk, Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b),
    Http.walk.crlf(Nat.add(g, String.length(b)), l, r ++ b, True{}, s => Http.walk(Nat.add(g, String.length(b)), s)),
    Http.walk.more(Http.walk(g, Http.octs.drop(r, Nat.add(l, 2n))), String.length(b), b),
    Equal.trans(Http.Walk, Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b),
      Http.walk.crlf(Nat.add(g, String.length(b)), l, r ++ b, Bool.and(
        Http.octs.has(r ++ b, Nat.add(l, 2n)), String.starts_with(r ++ b, "\r\n")), s => Http.walk(Nat.add(g,
            String.length(b)), s)),
      Http.walk.crlf(Nat.add(g, String.length(b)), l, r ++ b, True{}, s => Http.walk(Nat.add(g,
          String.length(b)), s)), s1,
      Equal.cong(Bool, Http.Walk, x => Http.walk.crlf(Nat.add(g, String.length(b)), l, r ++ b, x,
          s => Http.walk(Nat.add(g, String.length(b)), s)),
        Bool.and(Http.octs.has(r ++ b, Nat.add(l, 2n)),
          String.starts_with(r ++ b, "\r\n")), True{}, rd2)),
    Equal.trans(Http.Walk,
      Http.walk(Nat.add(g, String.length(b)), Http.octs.drop(r ++ b, Nat.add(l, 2n))),
      Http.walk(Nat.add(g, String.length(b)), Http.octs.drop(r, Nat.add(l, 2n)) ++ b),
      Http.walk.more(Http.walk(g, Http.octs.drop(r, Nat.add(l, 2n))), String.length(b), b),
      Equal.cong(String, Http.Walk, x => Http.walk(Nat.add(g, String.length(b)), x),
        Http.octs.drop(r ++ b, Nat.add(l, 2n)),
        Http.octs.drop(r, Nat.add(l, 2n)) ++ b, drop_app(r, b, Nat.add(l, 2n), eh)),
      ih(Http.octs.drop(r, Nat.add(l, 2n)))))

law wm.crlf:
  for +g: Nat
  for rest: String
  for +b: String
  for +l: Nat
  for +r: String
  for rd: Bool
  for +erd: {rd == Bool.and(Http.octs.has(r, Nat.add(l, 2n)),
    String.starts_with(r, "\r\n")) : Bool}
  for +s1: {Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b) == Http.walk.data(Nat.add(g,
      String.length(b)), Http.Over{l, r ++ b}, s => Http.walk(Nat.add(g, String.length(b)), s))
    : Http.Walk}
  for ih: @s: String ->
    {Http.walk(Nat.add(g, String.length(b)), s ++ b) == Http.walk.more(Http.walk(g, s), String.length(b), b)
      : Http.Walk}
  {Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b) == Http.walk.more(Http.walk.crlf(g, l, r, rd,
      s => Http.walk(g, s)), String.length(b), b) : Http.Walk}

def wm.crlf(g, rest, b, l, r, rd, erd, s1, ih):
  match rd:
    case True{}:
      wm.ready(g, rest, b, l, r, Equal.sym(Bool, True{}, Bool.and(
        Http.octs.has(r, Nat.add(l, 2n)), String.starts_with(r, "\r\n")), erd), s1, ih)
    case False{}:
      s1

law wm.data:
  for +g: Nat
  for rest: String
  for +b: String
  for sk: Http.Skip
  for +s1: {Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b) == Http.walk.data(Nat.add(g,
      String.length(b)), sk.then(sk, b), s => Http.walk(Nat.add(g, String.length(b)), s)) : Http.Walk}
  for ih: @s: String ->
    {Http.walk(Nat.add(g, String.length(b)), s ++ b) == Http.walk.more(Http.walk(g, s), String.length(b), b)
      : Http.Walk}
  {Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b) == Http.walk.more(Http.walk.data(g, sk,
      s => Http.walk(g, s)), String.length(b), b) : Http.Walk}

def wm.data(g, rest, b, sk, s1, ih):
  match sk:
    case Http.Short{o}:
      s1
    case Http.Over{+l, +r}:
      wm.crlf(g, rest, b, l, r, Bool.and(Http.octs.has(r, Nat.add(l, 2n)),
        String.starts_with(r, "\r\n")), {==}, s1, ih)

law wm.trail:
  for +g: Nat
  for +rest: String
  for +b: String
  for +after: String
  for t: Bool
  for +et: {t == Http.chunks.trailer(after) : Bool}
  for +s1: {Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b) == Http.walk.trail(Nat.add(g,
      String.length(b)), rest ++ b,
    Http.chunks.trailer(after ++ b)) : Http.Walk}
  {Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b) == Http.walk.more(Http.walk.trail(g, rest, t),
      String.length(b), b) : Http.Walk}

def wm.trail(g, rest, b, after, t, et, s1):
  match t:
    case True{}:
      Equal.trans(Http.Walk, Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b),
        Http.walk.trail(Nat.add(g, String.length(b)), rest ++ b, Http.chunks.trailer(after ++ b)),
        Http.Ended{}, s1,
        Equal.cong(Bool, Http.Walk, x => Http.walk.trail(Nat.add(g, String.length(b)), rest ++ b, x),
          Http.chunks.trailer(after ++ b), True{}, trailer_app(after, b, et)))
    case False{}:
      {==}

law wm.size:
  for +g: Nat
  for +rest: String
  for +b: String
  for +after: String
  for +n: Nat
  for z: Bool
  for +s1: {Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b) == Http.walk.size(Nat.add(g,
      String.length(b)), rest ++ b, after ++ b, n, z, s => Http.walk(Nat.add(g, String.length(b)), s))
    : Http.Walk}
  for ih: @s: String ->
    {Http.walk(Nat.add(g, String.length(b)), s ++ b) == Http.walk.more(Http.walk(g, s), String.length(b), b)
      : Http.Walk}
  {Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b) == Http.walk.more(Http.walk.size(g, rest, after, n,
      z, s => Http.walk(g, s)), String.length(b), b)
    : Http.Walk}

def wm.size(g, rest, b, after, n, z, s1, ih):
  match z:
    case True{}:
      wm.trail(g, rest, b, after, Http.chunks.trailer(after), {==}, s1)
    case False{}:
      wm.data(g, rest, b, Http.octs.skip(after, n),
        Equal.trans(Http.Walk, Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b),
          Http.walk.data(Nat.add(g, String.length(b)), Http.octs.skip(after ++ b, n),
              s => Http.walk(Nat.add(g, String.length(b)), s)),
          Http.walk.data(Nat.add(g, String.length(b)), sk.then(Http.octs.skip(after, n), b),
              s => Http.walk(Nat.add(g, String.length(b)), s)), s1,
          Equal.cong(Http.Skip, Http.Walk, x => Http.walk.data(Nat.add(g, String.length(b)), x,
              s => Http.walk(Nat.add(g, String.length(b)), s)),
            Http.octs.skip(after ++ b, n), sk.then(Http.octs.skip(after, n), b),
            skip_app(after, b, n))), ih)

law wm.hex:
  for +g: Nat
  for +rest: String
  for +b: String
  for +before: String
  for +after: String
  for ok: Bool
  for +s1: {Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b) == Http.walk.hex(Nat.add(g,
      String.length(b)), rest ++ b, before, after ++ b, ok, s => Http.walk(Nat.add(g, String.length(b)), s))
    : Http.Walk}
  for ih: @s: String ->
    {Http.walk(Nat.add(g, String.length(b)), s ++ b) == Http.walk.more(Http.walk(g, s), String.length(b), b)
      : Http.Walk}
  {Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b) == Http.walk.more(Http.walk.hex(g, rest, before,
      after, ok, s => Http.walk(g, s)), String.length(b), b)
    : Http.Walk}

def wm.hex(g, rest, b, before, after, ok, s1, ih):
  match ok:
    case False{}:
      s1
    case True{}:
      wm.size(g, rest, b, after, Http.hexlen(before),
        Nat.is_eq(Http.hexlen(before), 0n), s1, ih)

law wm.at:
  for +g: Nat
  for +rest: String
  for +b: String
  for c: Http.Cut
  for +ec: {c == Http.divide(rest, "\r\n") : Http.Cut}
  for ih: @s: String ->
    {Http.walk(Nat.add(g, String.length(b)), s ++ b) == Http.walk.more(Http.walk(g, s), String.length(b), b)
      : Http.Walk}
  {Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b) == Http.walk.more(Http.walk.at(g, rest, c,
      s => Http.walk(g, s)), String.length(b), b) : Http.Walk}

def wm.at(g, rest, b, c, ec, ih):
  match c:
    case Http.NoCut{}:
      {==}
    case Http.Cut{+before, +after}:
      +cut = Equal.cong(Http.Cut, Bool, x => cut.is(x), Http.Cut{before, after},
        Http.divide(rest, "\r\n"), ec)
      +dv = Equal.trans(Http.Cut, Http.divide(rest ++ b, "\r\n"),
        cut.app(Http.divide(rest, "\r\n"), b), Http.Cut{before, after ++ b},
        divide_app(rest, "\r\n", b, cut),
        Equal.cong(Http.Cut, Http.Cut, x => cut.app(x, b), Http.divide(rest, "\r\n"),
          Http.Cut{before, after},
          Equal.sym(Http.Cut, Http.Cut{before, after}, Http.divide(rest, "\r\n"), ec)))
      wm.hex(g, rest, b, before, after, Http.hex.well(Http.chunks.token(before)),
        Equal.cong(Http.Cut, Http.Walk, x => Http.walk.at(Nat.add(g, String.length(b)), rest ++ b, x,
            s => Http.walk(Nat.add(g, String.length(b)), s)),
          Http.divide(rest ++ b, "\r\n"), Http.Cut{before, after ++ b}, dv), ih)

def L1.walk_more(f, rest, b):
  match f:
    case 0n:
      {==}
    case 1n+f2:
      +g = f2
      wm.at(g, rest, b, Http.divide(rest, "\r\n"), {==},
        s => L1.walk_more(g, s, b))

law hd.body:
  for f: Http.Frame
  for +after: String
  {Http.hear.done(Http.hear.body(f, after)) == Http.whole.of(f, after) : Bool}

def hd.body(f, after):
  match f:
    case Http.Bare{}:
      {==}
    case Http.Sized{n}:
      {==}
    case Http.Chunked{}:
      L1.walk_done(String.length(after), after)
    case Http.Closed{}:
      {==}

law hd.step:
  for +g: Nat
  for +asked: Bool
  for +ls: List<&2, String>
  for +after: String
  for i: Bool
  for ih: @s: String ->
    {Http.hear.done(Http.hear.go(g, asked, s))
      == Http.whole.go(g, asked, Http.divide(s, "\r\n\r\n")) : Bool}
  {Http.hear.done(Http.hear.step(asked, ls, after, i, s => Http.hear.go(g, asked, s)))
    == Http.whole.step(asked, ls, after, i, cut => Http.whole.go(g, asked, cut)) : Bool}

def hd.step(_g, asked, ls, after, i, ih):
  match i:
    case True{}:
      ih(after)
    case False{}:
      hd.body(Http.frame(Bool.or(asked, Http.status.bare(Http.status.of(ls))),
        Http.head.go(ls, "transfer-encoding"),
        Http.head.values(ls, "content-length")), after)

law hd.at:
  for +g: Nat
  for +asked: Bool
  for raw: String
  for c: Http.Cut
  for ih: @s: String ->
    {Http.hear.done(Http.hear.go(g, asked, s))
      == Http.whole.go(g, asked, Http.divide(s, "\r\n\r\n")) : Bool}
  {Http.hear.done(Http.hear.at(g, asked, raw, c, s => Http.hear.go(g, asked, s)))
    == Http.whole.at(asked, c, cut => Http.whole.go(g, asked, cut)) : Bool}

def hd.at(g, asked, _raw, c, ih):
  match c:
    case Http.NoCut{}:
      {==}
    case Http.Cut{before, +after}:
      +ls = String.lines(before)
      hd.step(g, asked, ls, after, Http.status.interim(Http.status.of(ls)), ih)

law hd:
  for f: Nat
  for +asked: Bool
  for +raw: String
  {Http.hear.done(Http.hear.go(f, asked, raw))
    == Http.whole.go(f, asked, Http.divide(raw, "\r\n\r\n")) : Bool}

def hd(f, asked, raw):
  match f:
    case 0n:
      {==}
    case 1n+f2:
      +g = f2
      hd.at(g, asked, raw, Http.divide(raw, "\r\n\r\n"), s => hd(g, asked, s))

def L1.hear_done(method, raw):
  hd(String.length(raw), String.eq(method, "HEAD"), raw)

law add_assoc:
  for x: Nat
  for +y: Nat
  for +z: Nat
  {Nat.add(Nat.add(x, y), z) == Nat.add(x, Nat.add(y, z)) : Nat}

def add_assoc(x, y, z):
  match x:
    case 0n:
      {==}
    case 1n+p:
      Equal.cong(Nat, Nat, k => 1n+k, Nat.add(Nat.add(p, y), z),
        Nat.add(p, Nat.add(y, z)), add_assoc(p, y, z))

law u8len_app:
  for a: String
  for +b: String
  {Http.octs.len(a ++ b) == Nat.add(Http.octs.len(a), Http.octs.len(b)) : Nat}

def u8len_app(a, b):
  match a:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      +w = Http.octs.width(Char.to_u32(h))
      Equal.trans(Nat, Nat.add(w, Http.octs.len(t ++ b)),
        Nat.add(w, Nat.add(Http.octs.len(t), Http.octs.len(b))),
        Nat.add(Nat.add(w, Http.octs.len(t)), Http.octs.len(b)),
        Equal.cong(Nat, Nat, k => Nat.add(w, k), Http.octs.len(t ++ b),
          Nat.add(Http.octs.len(t), Http.octs.len(b)), u8len_app(t, b)),
        Equal.sym(Nat, Nat.add(Nat.add(w, Http.octs.len(t)), Http.octs.len(b)),
          Nat.add(w, Nat.add(Http.octs.len(t), Http.octs.len(b))),
          add_assoc(w, Http.octs.len(t), Http.octs.len(b))))

law hm.body:
  for f: Http.Frame
  for +after: String
  for +b: String
  {Http.hear.body(f, after ++ b) == Http.hear.more(Http.hear.body(f, after), b)
    : Http.Hear}

def hm.body(f, after, b):
  match f:
    case Http.Bare{}:
      {==}
    case Http.Sized{+n}:
      Equal.cong(Nat, Http.Hear, k => Http.Count{n, k}, Http.octs.len(after ++ b),
        Nat.add(Http.octs.len(after), Http.octs.len(b)), u8len_app(after, b))
    case Http.Chunked{}:
      Equal.cong(Http.Walk, Http.Hear, w => Http.Walking{w},
        Http.walk(String.length(after ++ b), after ++ b),
        Http.walk.more(Http.walk(String.length(after), after), String.length(b), b),
        Equal.trans(Http.Walk, Http.walk(String.length(after ++ b), after ++ b),
          Http.walk(Nat.add(String.length(after), String.length(b)), after ++ b),
          Http.walk.more(Http.walk(String.length(after), after), String.length(b), b),
          Equal.cong(Nat, Http.Walk, k => Http.walk(k, after ++ b),
            String.length(after ++ b), Nat.add(String.length(after), String.length(b)),
            len_app(after, b)),
          L1.walk_more(String.length(after), after, b)))
    case Http.Closed{}:
      {==}

law hm.step:
  for +g: Nat
  for +asked: Bool
  for +raw: String
  for +b: String
  for +ls: List<&2, String>
  for +after: String
  for i: Bool
  for +s1: {Http.hear.go(Nat.add(1n+g, String.length(b)), asked, raw ++ b) == Http.hear.step(asked, ls,
      after ++ b, i, s => Http.hear.go(Nat.add(g, String.length(b)), asked, s)) : Http.Hear}
  for ih: @s: String ->
    {Http.hear.go(Nat.add(g, String.length(b)), asked, s ++ b)
      == Http.hear.more(Http.hear.go(g, asked, s), b) : Http.Hear}
  {Http.hear.go(Nat.add(1n+g, String.length(b)), asked, raw ++ b) == Http.hear.more(Http.hear.step(asked, ls,
      after, i, s => Http.hear.go(g, asked, s)), b)
    : Http.Hear}

def hm.step(g, asked, raw, b, ls, after, i, s1, ih):
  match i:
    case True{}:
      Equal.trans(Http.Hear, Http.hear.go(Nat.add(1n+g, String.length(b)), asked, raw ++ b),
          Http.hear.go(Nat.add(g, String.length(b)), asked, after ++ b),
        Http.hear.more(Http.hear.go(g, asked, after), b), s1, ih(after))
    case False{}:
      +fr = Http.frame(Bool.or(asked, Http.status.bare(Http.status.of(ls))),
        Http.head.go(ls, "transfer-encoding"),
        Http.head.values(ls, "content-length"))
      Equal.trans(Http.Hear, Http.hear.go(Nat.add(1n+g, String.length(b)), asked, raw ++ b),
          Http.hear.body(fr, after ++ b),
        Http.hear.more(Http.hear.body(fr, after), b), s1, hm.body(fr, after, b))

law hm.at:
  for +g: Nat
  for +asked: Bool
  for +raw: String
  for +b: String
  for c: Http.Cut
  for +ec: {c == Http.divide(raw, "\r\n\r\n") : Http.Cut}
  for ih: @s: String ->
    {Http.hear.go(Nat.add(g, String.length(b)), asked, s ++ b)
      == Http.hear.more(Http.hear.go(g, asked, s), b) : Http.Hear}
  {Http.hear.go(Nat.add(1n+g, String.length(b)), asked, raw ++ b) == Http.hear.more(Http.hear.at(g, asked,
      raw, c, s => Http.hear.go(g, asked, s)), b) : Http.Hear}

def hm.at(g, asked, raw, b, c, ec, ih):
  match c:
    case Http.NoCut{}:
      {==}
    case Http.Cut{+before, +after}:
      +cut = Equal.cong(Http.Cut, Bool, x => cut.is(x), Http.Cut{before, after},
        Http.divide(raw, "\r\n\r\n"), ec)
      +dv = Equal.trans(Http.Cut, Http.divide(raw ++ b, "\r\n\r\n"),
        cut.app(Http.divide(raw, "\r\n\r\n"), b), Http.Cut{before, after ++ b},
        divide_app(raw, "\r\n\r\n", b, cut),
        Equal.cong(Http.Cut, Http.Cut, x => cut.app(x, b), Http.divide(raw, "\r\n\r\n"),
          Http.Cut{before, after},
          Equal.sym(Http.Cut, Http.Cut{before, after}, Http.divide(raw, "\r\n\r\n"), ec)))
      +ls = String.lines(before)
      hm.step(g, asked, raw, b, ls, after, Http.status.interim(Http.status.of(ls)),
        Equal.cong(Http.Cut, Http.Hear,
          x => Http.hear.at(Nat.add(g, String.length(b)), asked, raw ++ b, x, s => Http.hear.go(Nat.add(g,
              String.length(b)), asked, s)),
          Http.divide(raw ++ b, "\r\n\r\n"), Http.Cut{before, after ++ b}, dv), ih)

law hm:
  for f: Nat
  for +asked: Bool
  for +raw: String
  for +b: String
  {Http.hear.go(Nat.add(f, String.length(b)), asked, raw ++ b)
    == Http.hear.more(Http.hear.go(f, asked, raw), b) : Http.Hear}

def hm(f, asked, raw, b):
  match f:
    case 0n:
      {==}
    case 1n+f2:
      +g = f2
      hm.at(g, asked, raw, b, Http.divide(raw, "\r\n\r\n"), {==}, s => hm(g, asked, s, b))

def L1.hear_more(method, a, b):
  +asked = String.eq(method, "HEAD")
  Equal.sym(Http.Hear, Http.hear.of(method, a ++ b),
    Http.hear.more(Http.hear.of(method, a), b),
    Equal.trans(Http.Hear, Http.hear.go(String.length(a ++ b), asked, a ++ b),
      Http.hear.go(Nat.add(String.length(a), String.length(b)), asked, a ++ b),
      Http.hear.more(Http.hear.go(String.length(a), asked, a), b),
      Equal.cong(Nat, Http.Hear, k => Http.hear.go(k, asked, a ++ b),
        String.length(a ++ b), Nat.add(String.length(a), String.length(b)), len_app(a, b)),
      hm(String.length(a), asked, a, b)))

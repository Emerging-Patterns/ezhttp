# proofs of laws/UnescapeUndoesEscape.bend
import Base
import ../src/html.bend as Html
import ../src/unescape.bend as Ref
import ../laws/UnescapeUndoesEscape.bend as Laws
import ./lemmas/BaseEqualities.bend as M1

# --- unescape after escape ---

# what a comparison that is not EQ cannot equal
def eq.cmp.emp(c: Cmp) -> Type:
  match c:
    case LT{}:
      Unit
    case EQ{}:
      Empty
    case GT{}:
      Unit

def eq.cmp.lt(e: {LT{} == EQ{} : Cmp}) -> Empty:
  %e : eq.cmp.emp(_)
  Unit{}

def eq.cmp.gt(e: {GT{} == EQ{} : Cmp}) -> Empty:
  %e : eq.cmp.emp(_)
  Unit{}

def eq.bool_cmp_eq(a: Bool, b: Bool, e: {Bool.cmp(a, b) == EQ{} : Cmp})
  -> {a == b : Bool}:
  match a b:
    case False{} False{}:
      {==}
    case False{} True{}:
      M1.eq.bit.gone(&2, {False{} == True{} : Bool}, eq.cmp.lt(e))
    case True{} False{}:
      M1.eq.bit.gone(&2, {True{} == False{} : Bool}, eq.cmp.gt(e))
    case True{} True{}:
      {==}

def eq.fin.t(ab: Bool, bb: Bool, t: Cmp,
  e: {Word.cmp.fin(ab, bb, t) == EQ{} : Cmp}) -> {t == EQ{} : Cmp}:
  match t:
    case LT{}:
      M1.eq.bit.gone(&2, {LT{} == EQ{} : Cmp}, eq.cmp.lt(e))
    case EQ{}:
      {==}
    case GT{}:
      M1.eq.bit.gone(&2, {GT{} == EQ{} : Cmp}, eq.cmp.gt(e))

def eq.fin.b(ab: Bool, bb: Bool, t: Cmp,
  e: {Word.cmp.fin(ab, bb, t) == EQ{} : Cmp}) -> {Bool.cmp(ab, bb) == EQ{} : Cmp}:
  match t:
    case LT{}:
      M1.eq.bit.gone(&2, {Bool.cmp(ab, bb) == EQ{} : Cmp}, eq.cmp.lt(e))
    case EQ{}:
      e
    case GT{}:
      M1.eq.bit.gone(&2, {Bool.cmp(ab, bb) == EQ{} : Cmp}, eq.cmp.gt(e))

def eq.word_cmp_eq(n: Nat, a: Word(n), b: Word(n),
  +e: {Word.cmp(n, a, b) == EQ{} : Cmp}) -> {a == b : Word(n)}:
  match n:
    case 0n:
      match a b:
        case WNil{} WNil{}:
          {==}
    case 1n+(+p):
      match a b:
        case WCon{+ab, +at} WCon{+bb, +bt}:
          be = eq.bool_cmp_eq(ab, bb, eq.fin.b(ab, bb, Word.cmp(p, at, bt), e))
          we = eq.word_cmp_eq(p, at, bt, eq.fin.t(ab, bb, Word.cmp(p, at, bt), e))
          %be : {WCon{ab, at} == WCon{_, bt} : Word(1n+p)}
          %we : {WCon{ab, at} == WCon{ab, _} : Word(1n+p)}
          {==}

def eq.cmp_is_eq(t: Cmp, e: {Cmp.is_eq(t) == True{} : Bool})
  -> {t == EQ{} : Cmp}:
  match t:
    case LT{}:
      M1.eq.bit.absurd(&2, {LT{} == EQ{} : Cmp}, e)
    case EQ{}:
      {==}
    case GT{}:
      M1.eq.bit.absurd(&2, {GT{} == EQ{} : Cmp}, e)

def eq.char_eq_true(c: Char, d: Char, e: {Char.is_eq(c, d) == True{} : Bool})
  -> {c == d : Char}:
  match c d:
    case Chr{U32{+w}} Chr{U32{+v}}:
      we = eq.word_cmp_eq(32n, w, v, eq.cmp_is_eq(Word.cmp(32n, w, v), e))
      %we : {Chr{U32{w}} == Chr{U32{_}} : Char}
      {==}

# a character that is not `&`, `<`, `>`, `"` or `'` scans as itself
def rt.other(+c: Char, x: String, e: {False{} == Char.is_eq(c, '&') : Bool})
  -> {Ref.scan(SCon{c, x}, Ref.Txt{}) == SCon{c, Ref.scan(x, Ref.Txt{})}
    : String}:
  %e : {Ref.text.of(c, st2 => Ref.scan(x, st2), _)
    == SCon{c, Ref.scan(x, Ref.Txt{})} : String}
  {==}

def rt.sq(+c: Char, x: String, ea: {False{} == Char.is_eq(c, '&') : Bool},
  b: Bool, e: {Char.is_eq(c, '\'') == b : Bool})
  -> {Ref.scan(Html.one.sq(c, x, b), Ref.Txt{})
    == SCon{c, Ref.scan(x, Ref.Txt{})} : String}:
  match b:
    case True{}:
      ce = Equal.sym(Char, c, '\'', eq.char_eq_true(c, '\'', e))
      %ce : {Ref.scan("&#39;" ++ x, Ref.Txt{})
        == SCon{_, Ref.scan(x, Ref.Txt{})} : String}
      {==}
    case False{}:
      rt.other(c, x, ea)

def rt.dq(+c: Char, x: String, ea: {False{} == Char.is_eq(c, '&') : Bool},
  b: Bool, e: {Char.is_eq(c, '"') == b : Bool})
  -> {Ref.scan(Html.one.dq(c, x, b), Ref.Txt{})
    == SCon{c, Ref.scan(x, Ref.Txt{})} : String}:
  match b:
    case True{}:
      ce = Equal.sym(Char, c, '"', eq.char_eq_true(c, '"', e))
      %ce : {Ref.scan("&#34;" ++ x, Ref.Txt{})
        == SCon{_, Ref.scan(x, Ref.Txt{})} : String}
      {==}
    case False{}:
      rt.sq(c, x, ea, Char.is_eq(c, '\''), {==})

def rt.gt(+c: Char, x: String, ea: {False{} == Char.is_eq(c, '&') : Bool},
  b: Bool, e: {Char.is_eq(c, '>') == b : Bool})
  -> {Ref.scan(Html.one.gt(c, x, b), Ref.Txt{})
    == SCon{c, Ref.scan(x, Ref.Txt{})} : String}:
  match b:
    case True{}:
      ce = Equal.sym(Char, c, '>', eq.char_eq_true(c, '>', e))
      %ce : {Ref.scan("&gt;" ++ x, Ref.Txt{})
        == SCon{_, Ref.scan(x, Ref.Txt{})} : String}
      {==}
    case False{}:
      rt.dq(c, x, ea, Char.is_eq(c, '"'), {==})

def rt.lt(+c: Char, x: String, ea: {False{} == Char.is_eq(c, '&') : Bool},
  b: Bool, e: {Char.is_eq(c, '<') == b : Bool})
  -> {Ref.scan(Html.one.lt(c, x, b), Ref.Txt{})
    == SCon{c, Ref.scan(x, Ref.Txt{})} : String}:
  match b:
    case True{}:
      ce = Equal.sym(Char, c, '<', eq.char_eq_true(c, '<', e))
      %ce : {Ref.scan("&lt;" ++ x, Ref.Txt{})
        == SCon{_, Ref.scan(x, Ref.Txt{})} : String}
      {==}
    case False{}:
      rt.gt(c, x, ea, Char.is_eq(c, '>'), {==})

def rt.amp(+c: Char, x: String, b: Bool, e: {Char.is_eq(c, '&') == b : Bool})
  -> {Ref.scan(Html.one.amp(c, x, b), Ref.Txt{})
    == SCon{c, Ref.scan(x, Ref.Txt{})} : String}:
  match b:
    case True{}:
      ce = Equal.sym(Char, c, '&', eq.char_eq_true(c, '&', e))
      %ce : {Ref.scan("&amp;" ++ x, Ref.Txt{})
        == SCon{_, Ref.scan(x, Ref.Txt{})} : String}
      {==}
    case False{}:
      rt.lt(c, x, Equal.sym(Bool, Char.is_eq(c, '&'), False{}, e),
        Char.is_eq(c, '<'), {==})

def rt.go(s: String)
  -> {Ref.scan(Html.escape.onto(s, ""), Ref.Txt{}) == s : String}:
  match s:
    case SNil{}:
      {==}
    case SCon{+c, +t}:
      Equal.trans(String,
        Ref.scan(Html.one(c, Html.escape.onto(t, "")), Ref.Txt{}),
        SCon{c, Ref.scan(Html.escape.onto(t, ""), Ref.Txt{})},
        SCon{c, t},
        rt.amp(c, Html.escape.onto(t, ""), Char.is_eq(c, '&'), {==}),
        Equal.cong(String, String, y => SCon{c, y},
          Ref.scan(Html.escape.onto(t, ""), Ref.Txt{}), t, rt.go(t)))

def Laws.ref_round(s):
  rt.go(s)

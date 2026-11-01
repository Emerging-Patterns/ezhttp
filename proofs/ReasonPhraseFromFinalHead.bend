# proofs of laws/ReasonPhraseFromFinalHead.bend
import Base
import ../src/http.bend as Http
import ../laws/ReasonPhraseFromFinalHead.bend as Laws
import ../laws/defs/CharacterAbsent.bend as D1
import ./lemmas/BaseEqualities.bend as M1
import ./lemmas/DropNothing.bend as M2

# --- a response's reason phrase ---

def Laws.phrase_to(_raw):
  {==}

def Laws.phrase_fuel(_c):
  {==}

def Laws.phrase_open(_f):
  {==}

def Laws.phrase_interim(f, before, after, e):
  %e : {Http.phrase.to.step(String.lines(before), after, _,
    cut => Http.phrase.to.go(f, cut))
    == Http.phrase.to.go(f, Http.divide(after, "\r\n\r\n")) : String}
  {==}

def Laws.phrase_final(f, before, after, e):
  %e : {Http.phrase.to.step(String.lines(before), after, _,
    cut => Http.phrase.to.go(f, cut))
    == Http.phrase.line(Http.first(String.lines(before))) : String}
  {==}

# LAW: a string that avoids a character does not start with it
law avoids.head:
  for +h: Char
  for +t: String
  for +c: Char
  for e: {True{} == D1.avoids(SCon{h, t}, c) : Bool}
  {False{} == Char.is_eq(h, c) : Bool}

def avoids.head(h, t, c, e):
  Equal.sym(Bool, Char.is_eq(h, c), False{},
    M1.eq.not.true(Char.is_eq(h, c),
      M1.eq.and.left(Bool.not(Char.is_eq(h, c)), D1.avoids(t, c),
        Equal.sym(Bool, True{}, D1.avoids(SCon{h, t}, c), e))))

# LAW: a string that avoids a character has a tail that avoids it
law avoids.tail:
  for +h: Char
  for +t: String
  for +c: Char
  for e: {True{} == D1.avoids(SCon{h, t}, c) : Bool}
  {True{} == D1.avoids(t, c) : Bool}

def avoids.tail(h, t, c, e):
  Equal.sym(Bool, D1.avoids(t, c), True{},
    M1.eq.and.right(Bool.not(Char.is_eq(h, c)), D1.avoids(t, c),
      Equal.sym(Bool, True{}, D1.avoids(SCon{h, t}, c), e)))

# LAW: one step of dividing at the first SP, past a character that is not one
law sp_cut.step:
  for +h: Char
  for +t: String
  for +b: String
  for f: {False{} == Char.is_eq(h, ' ') : Bool}
  for ih: {Http.divide.go(String.append(t, SCon{' ', b}), " ", 1n)
    == Http.Cut{t, b} : Http.Cut}
  {Http.divide.go(String.append(SCon{h, t}, SCon{' ', b}), " ", 1n)
    == Http.Cut{SCon{h, t}, b} : Http.Cut}

def sp_cut.step(h, t, b, f, ih):
  %f : {Http.divide.step(
    String.starts_with.go.if("", String.append(t, SCon{' ', b}), _), h,
    String.append(t, SCon{' ', b}), 1n,
    _u => Http.divide.go(String.append(t, SCon{' ', b}), " ", 1n))
    == Http.Cut{SCon{h, t}, b} : Http.Cut}
  Equal.cong(Http.Cut, Http.Cut, r => Http.divide.push(h, r),
    Http.divide.go(String.append(t, SCon{' ', b}), " ", 1n), Http.Cut{t, b},
    ih)

# LAW: a text that holds no SP before one divides there
law sp_cut:
  for +a: String
  for +b: String
  for +e: {True{} == D1.avoids(a, ' ') : Bool}
  {Http.divide.go(String.append(a, SCon{' ', b}), " ", 1n)
    == Http.Cut{a, b} : Http.Cut}

def sp_cut(a, b, e):
  match a:
    case SNil{}:
      Equal.cong(String, Http.Cut, x => Http.Cut{"", x}, String.drop(b, 0n),
        b, M2.eq.drop_zero(b))
    case SCon{+h, +t}:
      sp_cut.step(h, t, b, avoids.head(h, t, ' ', e),
        sp_cut(t, b, avoids.tail(h, t, ' ', e)))

# LAW: one step of dividing a text with no SP
law sp_none.step:
  for +h: Char
  for +t: String
  for f: {False{} == Char.is_eq(h, ' ') : Bool}
  for ih: {Http.divide.go(t, " ", 1n) == Http.NoCut{} : Http.Cut}
  {Http.divide.go(SCon{h, t}, " ", 1n) == Http.NoCut{} : Http.Cut}

def sp_none.step(h, t, f, ih):
  %f : {Http.divide.step(String.starts_with.go.if("", t, _), h, t, 1n,
    _u => Http.divide.go(t, " ", 1n)) == Http.NoCut{} : Http.Cut}
  Equal.cong(Http.Cut, Http.Cut, r => Http.divide.push(h, r),
    Http.divide.go(t, " ", 1n), Http.NoCut{}, ih)

# LAW: a text with no SP does not divide at one
law sp_none:
  for +a: String
  for +e: {True{} == D1.avoids(a, ' ') : Bool}
  {Http.divide.go(a, " ", 1n) == Http.NoCut{} : Http.Cut}

def sp_none(a, e):
  match a:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      sp_none.step(h, t, avoids.head(h, t, ' ', e),
        sp_none(t, avoids.tail(h, t, ' ', e)))

# LAW: one step of the chop, past a character that is not CR
law chop.step:
  for +h: Char
  for +t: String
  for +x: String
  for f: {False{} == Char.is_eq(h, '\r') : Bool}
  for ih: {Http.phrase.chop(x) == t : String}
  {Http.phrase.chop(SCon{h, x}) == SCon{h, t} : String}

def chop.step(h, t, x, f, ih):
  %f : {Http.phrase.chop.at(_, h, x, _u => Http.phrase.chop(x))
    == SCon{h, t} : String}
  Equal.cong(String, String, y => SCon{h, y}, Http.phrase.chop(x), t, ih)

# LAW: a text with no CR is its own chop
law chop.keep:
  for +r: String
  for +e: {True{} == D1.avoids(r, '\r') : Bool}
  {Http.phrase.chop(r) == r : String}

def chop.keep(r, e):
  match r:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      chop.step(h, t, t, avoids.head(h, t, '\r', e),
        chop.keep(t, avoids.tail(h, t, '\r', e)))

# LAW: the chop of a text with no CR and then a CR is the text
law chop.cr:
  for +r: String
  for +e: {True{} == D1.avoids(r, '\r') : Bool}
  {Http.phrase.chop(String.append(r, "\r")) == r : String}

def chop.cr(r, e):
  match r:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      chop.step(h, t, String.append(t, "\r"), avoids.head(h, t, '\r', e),
        chop.cr(t, avoids.tail(h, t, '\r', e)))

def Laws.phrase_line(v, c, r, e1, e2, e3):
  Equal.trans(String,
    Http.phrase.line(String.append(v, SCon{' ', String.append(c, SCon{' ', r})})),
    Http.phrase.code(Http.Cut{c, r}),
    r,
    Equal.trans(String,
      Http.phrase.line(String.append(v, SCon{' ', String.append(c, SCon{' ', r})})),
      Http.phrase.after(Http.Cut{v, String.append(c, SCon{' ', r})}),
      Http.phrase.code(Http.Cut{c, r}),
      Equal.cong(Http.Cut, String, k => Http.phrase.after(k),
        Http.divide.go(String.append(v, SCon{' ', String.append(c, SCon{' ', r})}), " ", 1n),
        Http.Cut{v, String.append(c, SCon{' ', r})},
        sp_cut(v, String.append(c, SCon{' ', r}), e1)),
      Equal.cong(Http.Cut, String, k => Http.phrase.code(k),
        Http.divide.go(String.append(c, SCon{' ', r}), " ", 1n),
        Http.Cut{c, r}, sp_cut(c, r, e2))),
    chop.keep(r, e3))

def Laws.phrase_line_cr(v, c, r, e1, e2, e3):
  Equal.trans(String,
    Http.phrase.line(String.append(v, SCon{' ', String.append(c,
      SCon{' ', String.append(r, "\r")})})),
    Http.phrase.code(Http.Cut{c, String.append(r, "\r")}),
    r,
    Equal.trans(String,
      Http.phrase.line(String.append(v, SCon{' ', String.append(c,
        SCon{' ', String.append(r, "\r")})})),
      Http.phrase.after(Http.Cut{v, String.append(c,
        SCon{' ', String.append(r, "\r")})}),
      Http.phrase.code(Http.Cut{c, String.append(r, "\r")}),
      Equal.cong(Http.Cut, String, k => Http.phrase.after(k),
        Http.divide.go(String.append(v, SCon{' ', String.append(c,
          SCon{' ', String.append(r, "\r")})}), " ", 1n),
        Http.Cut{v, String.append(c, SCon{' ', String.append(r, "\r")})},
        sp_cut(v, String.append(c, SCon{' ', String.append(r, "\r")}), e1)),
      Equal.cong(Http.Cut, String, k => Http.phrase.code(k),
        Http.divide.go(String.append(c, SCon{' ', String.append(r, "\r")}),
          " ", 1n),
        Http.Cut{c, String.append(r, "\r")},
        sp_cut(c, String.append(r, "\r"), e2))),
    chop.cr(r, e3))

def Laws.phrase_line_one(v, c, e1, e2):
  Equal.trans(String,
    Http.phrase.line(String.append(v, SCon{' ', c})),
    Http.phrase.after(Http.Cut{v, c}),
    "",
    Equal.cong(Http.Cut, String, k => Http.phrase.after(k),
      Http.divide.go(String.append(v, SCon{' ', c}), " ", 1n),
      Http.Cut{v, c}, sp_cut(v, c, e1)),
    Equal.cong(Http.Cut, String, k => Http.phrase.code(k),
      Http.divide.go(c, " ", 1n), Http.NoCut{}, sp_none(c, e2)))

def Laws.phrase_line_none(v, e):
  Equal.cong(Http.Cut, String, k => Http.phrase.after(k),
    Http.divide.go(v, " ", 1n), Http.NoCut{}, sp_none(v, e))

def Laws.phrase_heard(text):
  dz = Equal.sym(String, String.drop(text, 0n), text, M2.eq.drop_zero(text))
  %dz : {Http.phrase.to(_) == Http.phrase.to(text) : String}
  {==}

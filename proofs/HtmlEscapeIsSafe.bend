# proofs of laws/HtmlEscapeIsSafe.bend
import Base
import ../src/html.bend as Html
import ../laws/HtmlEscapeIsSafe.bend as Laws

# LAW: a character none of the five stays in the frame
law frame.sq:
  for +c: Char
  for rest: String
  for k: Bool
  for ek: {k == Char.is_eq(c, '\'') : Bool}
  for ea: {False{} == Char.is_eq(c, '&') : Bool}
  for el: {False{} == Char.is_eq(c, '<') : Bool}
  for eg: {False{} == Char.is_eq(c, '>') : Bool}
  for ed: {False{} == Char.is_eq(c, '"') : Bool}
  {Laws.html.framed(Html.one.sq(c, rest, k), Laws.Out{})
    == Laws.html.framed(rest, Laws.Out{}) : Bool}

def frame.sq(c, rest, k, ek, ea, el, eg, ed):
  match k:
    case True{}:
      {==}
    case False{}:
      %ea : {Bool.and(Laws.ent.out.ok(Char.is_eq(c, '<'), Char.is_eq(c, '>'),
        Char.is_eq(c, '"'), Char.is_eq(c, '\'')),
        Laws.html.framed(rest, Laws.ent.out.next(_)))
        == Laws.html.framed(rest, Laws.Out{}) : Bool}
      %el : {Bool.and(Laws.ent.out.ok(_, Char.is_eq(c, '>'),
        Char.is_eq(c, '"'), Char.is_eq(c, '\'')),
        Laws.html.framed(rest, Laws.Out{}))
        == Laws.html.framed(rest, Laws.Out{}) : Bool}
      %eg : {Bool.and(Laws.ent.out.ok(False{}, _,
        Char.is_eq(c, '"'), Char.is_eq(c, '\'')),
        Laws.html.framed(rest, Laws.Out{}))
        == Laws.html.framed(rest, Laws.Out{}) : Bool}
      %ed : {Bool.and(Laws.ent.out.ok(False{}, False{}, _,
        Char.is_eq(c, '\'')),
        Laws.html.framed(rest, Laws.Out{}))
        == Laws.html.framed(rest, Laws.Out{}) : Bool}
      %ek : {Bool.and(Laws.ent.out.ok(False{}, False{}, False{}, _),
        Laws.html.framed(rest, Laws.Out{}))
        == Laws.html.framed(rest, Laws.Out{}) : Bool}
      {==}

# LAW: a character that is not `&`, `<` or `>` stays in the frame
law frame.dq:
  for +c: Char
  for rest: String
  for k: Bool
  for ek: {k == Char.is_eq(c, '"') : Bool}
  for ea: {False{} == Char.is_eq(c, '&') : Bool}
  for el: {False{} == Char.is_eq(c, '<') : Bool}
  for eg: {False{} == Char.is_eq(c, '>') : Bool}
  {Laws.html.framed(Html.one.dq(c, rest, k), Laws.Out{})
    == Laws.html.framed(rest, Laws.Out{}) : Bool}

def frame.dq(c, rest, k, ek, ea, el, eg):
  match k:
    case True{}:
      {==}
    case False{}:
      frame.sq(c, rest, Char.is_eq(c, '\''), {==}, ea, el, eg, ek)

# LAW: a character that is not `&` or `<` stays in the frame
law frame.gt:
  for +c: Char
  for rest: String
  for k: Bool
  for ek: {k == Char.is_eq(c, '>') : Bool}
  for ea: {False{} == Char.is_eq(c, '&') : Bool}
  for el: {False{} == Char.is_eq(c, '<') : Bool}
  {Laws.html.framed(Html.one.gt(c, rest, k), Laws.Out{})
    == Laws.html.framed(rest, Laws.Out{}) : Bool}

def frame.gt(c, rest, k, ek, ea, el):
  match k:
    case True{}:
      {==}
    case False{}:
      frame.dq(c, rest, Char.is_eq(c, '"'), {==}, ea, el, ek)

# LAW: a character that is not `&` stays in the frame
law frame.lt:
  for +c: Char
  for rest: String
  for k: Bool
  for ek: {k == Char.is_eq(c, '<') : Bool}
  for ea: {False{} == Char.is_eq(c, '&') : Bool}
  {Laws.html.framed(Html.one.lt(c, rest, k), Laws.Out{})
    == Laws.html.framed(rest, Laws.Out{}) : Bool}

def frame.lt(c, rest, k, ek, ea):
  match k:
    case True{}:
      {==}
    case False{}:
      frame.gt(c, rest, Char.is_eq(c, '>'), {==}, ea, ek)

# LAW: one escaped character stays in the frame
law frame.amp:
  for +c: Char
  for rest: String
  for k: Bool
  for ek: {k == Char.is_eq(c, '&') : Bool}
  {Laws.html.framed(Html.one.amp(c, rest, k), Laws.Out{})
    == Laws.html.framed(rest, Laws.Out{}) : Bool}

def frame.amp(c, rest, k, ek):
  match k:
    case True{}:
      {==}
    case False{}:
      frame.lt(c, rest, Char.is_eq(c, '<'), {==}, ek)

# LAW: an escaped string stays in the frame, whatever follows it
law frame.onto:
  for s: String
  for +rest: String
  {Laws.html.framed(Html.escape.onto(s, rest), Laws.Out{})
    == Laws.html.framed(rest, Laws.Out{}) : Bool}

def frame.onto(s, rest):
  match s:
    case SNil{}:
      {==}
    case SCon{+c, +t}:
      Equal.trans(Bool,
        Laws.html.framed(Html.one(c, Html.escape.onto(t, rest)), Laws.Out{}),
        Laws.html.framed(Html.escape.onto(t, rest), Laws.Out{}),
        Laws.html.framed(rest, Laws.Out{}),
        frame.amp(c, Html.escape.onto(t, rest), Char.is_eq(c, '&'), {==}),
        frame.onto(t, rest))

def Laws.html_frame(s):
  frame.onto(s, "")

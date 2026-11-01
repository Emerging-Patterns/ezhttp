# For every string, the output holds no `<`, `>`, `"` or `'`, and every `&`
# in it opens one of `&amp;`, `&lt;`, `&gt;`, `&#34;`, `&#39;`.
import Base
import ../src/html.bend as Html

# where the laws/HtmlEscapeIsSafe.bend frame is, reading left to right:
# between entities, after `&`, after `&#`, after `&#3`, or owing exactly the
# rest of an entity
type Ent is Data:
  Out{}
  Amp{}
  Hash{}
  Three{}
  Want{c: Char, rest: String}

# between entities: anything but `<`, `>`, `"` and `'`
def ent.out.ok(lt: Bool, gt: Bool, dq: Bool, sq: Bool) -> Bool:
  Bool.not(Bool.or(lt, Bool.or(gt, Bool.or(dq, sq))))

# between entities, an `&` opens one
def ent.out.next(amp: Bool) -> Ent:
  Bool.pick(Ent, amp, Amp{}, Out{})

# what is owed after the rest of an entity's next character
def ent.want(rest: String) -> Ent:
  match rest:
    case SNil{}:
      Out{}
    case SCon{c, t}:
      Want{c, t}

# whether character c may come next
def ent.ok(+c: Char, st: Ent) -> Bool:
  match st:
    case Out{}:
      ent.out.ok(Char.is_eq(c, '<'), Char.is_eq(c, '>'), Char.is_eq(c, '"'),
        Char.is_eq(c, '\''))
    case Amp{}:
      Bool.or(Char.is_eq(c, 'a'), Bool.or(Char.is_eq(c, 'l'),
        Bool.or(Char.is_eq(c, 'g'), Char.is_eq(c, '#'))))
    case Hash{}:
      Char.is_eq(c, '3')
    case Three{}:
      Bool.or(Char.is_eq(c, '4'), Char.is_eq(c, '9'))
    case Want{w, t}:
      Char.is_eq(c, w)

# where the frame is after character c
def ent.next(+c: Char, st: Ent) -> Ent:
  match st:
    case Out{}:
      ent.out.next(Char.is_eq(c, '&'))
    case Amp{}:
      Bool.pick(Ent, Char.is_eq(c, 'a'), Want{'m', "p;"},
        Bool.pick(Ent, Char.is_eq(c, '#'), Hash{}, Want{'t', ";"}))
    case Hash{}:
      Three{}
    case Three{}:
      Want{';', ""}
    case Want{w, t}:
      ent.want(t)

# nothing is owed at the end
def ent.end(st: Ent) -> Bool:
  match st:
    case Out{}:
      True{}
    case Amp{}:
      False{}
    case Hash{}:
      False{}
    case Three{}:
      False{}
    case Want{w, t}:
      False{}

# the laws/HtmlEscapeIsSafe.bend frame: no `<`, `>`, `"` or `'`, and every
# `&` opens one of `&amp;`, `&lt;`, `&gt;`, `&#34;`, `&#39;`
def html.framed(str: String, +st: Ent) -> Bool:
  match str:
    case SNil{}:
      ent.end(st)
    case SCon{+c, tail}:
      Bool.and(ent.ok(c, st), html.framed(tail, ent.next(c, st)))

# LAW (frame): every escaped string holds no `<`, `>`, `"` or `'`, and each
# `&` in it opens one of the five entities
law html_frame:
  for s: String
  {html.framed(Html.escape(s), Out{}) == True{} : Bool}

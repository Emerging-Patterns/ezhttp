# proofs of laws/DotSegmentsRemoved.bend
import Base
import ../src/redirect.bend as Redirect
import ../laws/DotSegmentsRemoved.bend as Laws
import ./lemmas/BaseEqualities.bend as M1

def Laws.clean_path(_ss):
  {==}

def Laws.dots_nil(_out):
  {==}

def Laws.dots_dot(s, t, out, e):
  %e : {Redirect.redirect.dots.one(_, String.eq(s, ".."),
    List.is_empty(&2, String, t), s, out, o => Redirect.redirect.dots(t, o))
    == Redirect.redirect.dots(t,
      Redirect.redirect.dots.end(List.is_empty(&2, String, t), out))
    : List<&2, String>}
  {==}

def Laws.dots_up(s, t, out, e1, e2):
  %e1 : {Redirect.redirect.dots.one(_, String.eq(s, ".."),
    List.is_empty(&2, String, t), s, out, o => Redirect.redirect.dots(t, o))
    == Redirect.redirect.dots(t,
      Redirect.redirect.dots.end(List.is_empty(&2, String, t),
        Redirect.redirect.pop(out))) : List<&2, String>}
  %e2 : {Redirect.redirect.dots.up(_, List.is_empty(&2, String, t), s, out,
    o => Redirect.redirect.dots(t, o))
    == Redirect.redirect.dots(t,
      Redirect.redirect.dots.end(List.is_empty(&2, String, t),
        Redirect.redirect.pop(out))) : List<&2, String>}
  {==}

def Laws.dots_seg(s, t, out, e1, e2):
  %e1 : {Redirect.redirect.dots.one(_, String.eq(s, ".."),
    List.is_empty(&2, String, t), s, out, o => Redirect.redirect.dots(t, o))
    == Redirect.redirect.dots(t, s <> out) : List<&2, String>}
  %e2 : {Redirect.redirect.dots.up(_, List.is_empty(&2, String, t), s, out,
    o => Redirect.redirect.dots(t, o))
    == Redirect.redirect.dots(t, s <> out) : List<&2, String>}
  {==}

def Laws.dots_last(_out):
  {==}

def Laws.dots_inner(_out):
  {==}

def Laws.pop_nil(out, e):
  match out:
    case []:
      {==}
    case h <> t:
      M1.eq.bit.absurd(&2, {Redirect.redirect.pop(h <> t) == [] : List<&2, String>},
        Equal.sym(Bool, True{}, False{}, e))

def Laws.pop_cons(_s, _t):
  {==}

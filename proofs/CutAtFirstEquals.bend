# proofs of laws/CutAtFirstEquals.bend
import Base
import ../src/qs.bend as Qs
import ../laws/CutAtFirstEquals.bend as Laws
import ../laws/defs/CharacterAbsent.bend as D1
import ./lemmas/BaseEqualities.bend as M1

def Laws.qs_cut_found(s, r, e):
  match s:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      ne = Equal.sym(Bool, Char.is_eq(h, '='), False{},
        M1.eq.not.true(Char.is_eq(h, '='),
          M1.eq.and.left(Bool.not(Char.is_eq(h, '=')), D1.avoids(t, '='), e)))
      ih = Equal.sym(Maybe<&2, Qs.Kv()>,
        Qs.cut(String.append(t, SCon{'=', r})), Some{(t, r)},
        Laws.qs_cut_found(t, r,
          M1.eq.and.right(Bool.not(Char.is_eq(h, '=')), D1.avoids(t, '='), e)))
      %ne : {Qs.cut.at(h, String.append(t, SCon{'=', r}), _,
        _u => Qs.cut(String.append(t, SCon{'=', r})))
        == Some{(SCon{h, t}, r)} : Maybe<&2, Qs.Kv()>}
      %ih : {Qs.cut.push(h, _) == Some{(SCon{h, t}, r)}
        : Maybe<&2, Qs.Kv()>}
      {==}

def Laws.qs_cut_none(s, e):
  match s:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      ne = Equal.sym(Bool, Char.is_eq(h, '='), False{},
        M1.eq.not.true(Char.is_eq(h, '='),
          M1.eq.and.left(Bool.not(Char.is_eq(h, '=')), D1.avoids(t, '='), e)))
      ih = Equal.sym(Maybe<&2, Qs.Kv()>, Qs.cut(t), None{},
        Laws.qs_cut_none(t,
          M1.eq.and.right(Bool.not(Char.is_eq(h, '=')), D1.avoids(t, '='), e)))
      %ne : {Qs.cut.at(h, t, _, _u => Qs.cut(t)) == None{}
        : Maybe<&2, Qs.Kv()>}
      %ih : {Qs.cut.push(h, _) == None{} : Maybe<&2, Qs.Kv()>}
      {==}

# proofs of laws/RelativeLocationsMerge.bend
import Base
import ../src/redirect.bend as Redirect
import ../laws/RelativeLocationsMerge.bend as Laws
import ./lemmas/BaseEqualities.bend as M1

def Laws.against_query(_scheme, _host, _port, _path, _loc):
  {==}

def Laws.against_rel(_scheme, _host, _port, _path, _loc):
  {==}

def Laws.sort_query(loc, e1, e2, e3, e4):
  %e1 : {Redirect.redirect.sort.of(_, String.starts_with(loc, "/"),
    Redirect.redirect.stays(loc), String.starts_with(loc, "?")) == Redirect.Query{} : Redirect.Sort}
  %e2 : {Redirect.redirect.sort.abs(_, Redirect.redirect.stays(loc),
    String.starts_with(loc, "?")) == Redirect.Query{} : Redirect.Sort}
  %e3 : {Redirect.redirect.sort.stay(_, String.starts_with(loc, "?")) == Redirect.Query{} : Redirect.Sort}
  %e4 : {Redirect.redirect.sort.rel(_) == Redirect.Query{} : Redirect.Sort}
  {==}

def Laws.sort_rel(loc, e1, e2, e3, e4):
  %e1 : {Redirect.redirect.sort.of(_, String.starts_with(loc, "/"),
    Redirect.redirect.stays(loc), String.starts_with(loc, "?")) == Redirect.Rel{} : Redirect.Sort}
  %e2 : {Redirect.redirect.sort.abs(_, Redirect.redirect.stays(loc),
    String.starts_with(loc, "?")) == Redirect.Rel{} : Redirect.Sort}
  %e3 : {Redirect.redirect.sort.stay(_, String.starts_with(loc, "?")) == Redirect.Rel{} : Redirect.Sort}
  %e4 : {Redirect.redirect.sort.rel(_) == Redirect.Rel{} : Redirect.Sort}
  {==}

def Laws.rel_of(_base, _path, _query):
  {==}

def Laws.base_path(_path):
  {==}

def Laws.hier_first(_h, _t):
  {==}

def Laws.init_nil(ss, e):
  match ss:
    case []:
      {==}
    case h <> t:
      M1.eq.bit.absurd(&2, {Redirect.redirect.init(h <> t) == [] : List<&2, String>},
        Equal.sym(Bool, True{}, False{}, e))

def Laws.init_cons(_s, _t):
  {==}

def Laws.init_last(_s):
  {==}

def Laws.init_keep(_s, _u, _r):
  {==}

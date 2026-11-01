# proofs of laws/AbsoluteLocationsResolve.bend
import Base
import ../src/redirect.bend as Redirect
import ../laws/AbsoluteLocationsResolve.bend as Laws
import ./lemmas/BaseEqualities.bend as M1

def Laws.target_absolute(url, loc, e):
  %e : {Redirect.redirect.target.of(url, loc, _) == Some{loc}
    : Maybe<&2, String>}
  {==}

# --- redirect targets ---

def Laws.target_bad(url, loc, e1, _why, e2):
  %e1 : {Redirect.redirect.target.of(url, loc, _) == None{}
    : Maybe<&2, String>}
  %e2 : {Redirect.redirect.at(_, loc) == None{} : Maybe<&2, String>}
  {==}

def Laws.against_net(_scheme, _host, _port, _path, _loc):
  {==}

def Laws.against_abs(_scheme, _host, _port, _path, _loc):
  {==}

def Laws.against_stay(_scheme, _host, _port, _path, _loc):
  {==}

def Laws.sort_net(loc, e):
  %e : {Redirect.redirect.sort.of(_, String.starts_with(loc, "/"),
    Redirect.redirect.stays(loc), String.starts_with(loc, "?")) == Redirect.Net{} : Redirect.Sort}
  {==}

def Laws.sort_abs(loc, e1, e2):
  %e1 : {Redirect.redirect.sort.of(_, String.starts_with(loc, "/"),
    Redirect.redirect.stays(loc), String.starts_with(loc, "?")) == Redirect.Abs{} : Redirect.Sort}
  %e2 : {Redirect.redirect.sort.abs(_, Redirect.redirect.stays(loc),
    String.starts_with(loc, "?")) == Redirect.Abs{} : Redirect.Sort}
  {==}

def Laws.sort_stay(loc, e1, e2, e3):
  %e1 : {Redirect.redirect.sort.of(_, String.starts_with(loc, "/"),
    Redirect.redirect.stays(loc), String.starts_with(loc, "?")) == Redirect.Stay{} : Redirect.Sort}
  %e2 : {Redirect.redirect.sort.abs(_, Redirect.redirect.stays(loc),
    String.starts_with(loc, "?")) == Redirect.Stay{} : Redirect.Sort}
  %e3 : {Redirect.redirect.sort.stay(_, String.starts_with(loc, "?")) == Redirect.Stay{} : Redirect.Sort}
  {==}

def Laws.stays_on(_loc):
  {==}

def Laws.schemed_nil(s, e):
  match s:
    case SNil{}:
      {==}
    case SCon{h, t}:
      M1.eq.bit.absurd(&2, {Redirect.redirect.schemed(SCon{h, t}) == False{} : Bool},
        Equal.sym(Bool, True{}, False{}, e))

def Laws.schemed_colon(_t):
  {==}

def Laws.schemed_stop(c, t, e):
  %e : {Redirect.redirect.schemed.at(_, Char.is_eq(c, ':'),
    _u => Redirect.redirect.schemed(t)) == False{} : Bool}
  {==}

def Laws.schemed_other(c, t, e1, e2):
  %e2 : {Redirect.redirect.schemed.at(_, Char.is_eq(c, ':'),
    _u => Redirect.redirect.schemed(t)) == Redirect.redirect.schemed(t) : Bool}
  %e1 : {Redirect.redirect.schemed.colon(_, _u => Redirect.redirect.schemed(t))
    == Redirect.redirect.schemed(t) : Bool}
  {==}

def Laws.schemed_end(_c):
  {==}

def Laws.abs_of(_path, _query):
  {==}

# proofs of laws/RedirectsFollowLocation.bend
import Base
import ../src/redirect.bend as Redirect
import ../laws/RedirectsFollowLocation.bend as Laws

# --- redirects ---

def Laws.redir_go(_status, e, _n, url, loc, next, et):
  %e : {Redirect.redirect.on(url, loc, _) == Redirect.Go{next} : Redirect.Hop}
  %et : {Redirect.redirect.hop(_) == Redirect.Go{next} : Redirect.Hop}
  {==}

# a response whose Location has no target stops, redirect or not
law redir_no_target.on:
  for url: String
  for +loc: String
  for moved: Bool
  for et: {None{} == Redirect.redirect.target(url, loc) : Maybe<&2, String>}
  {Redirect.redirect.on(url, loc, moved) == Redirect.Stop{} : Redirect.Hop}

def redir_no_target.on(_url, _loc, moved, et):
  match moved:
    case True{}:
      %et : {Redirect.redirect.hop(_) == Redirect.Stop{} : Redirect.Hop}
      {==}
    case False{}:
      {==}

def Laws.redir_no_target(status, left, url, loc, et):
  match left:
    case 0n:
      {==}
    case 1n+p:
      redir_no_target.on(url, loc, Redirect.redirect.is(status), et)

def Laws.redir_plan_location(_left, _url, _status, _hs):
  {==}

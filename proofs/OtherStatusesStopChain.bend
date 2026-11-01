# proofs of laws/OtherStatusesStopChain.bend
import Base
import ../src/redirect.bend as Redirect
import ../laws/OtherStatusesStopChain.bend as Laws

def Laws.redir_other(_status, e, left, url, loc):
  match left:
    case 0n:
      {==}
    case 1n+p:
      %e : {Redirect.redirect.on(url, loc, _) == Redirect.Stop{}
        : Redirect.Hop}
      {==}

def Laws.redir_zero(_url, _status, _loc):
  {==}

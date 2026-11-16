# proofs of laws/UrlFragmentHidesQuery.bend
import Base
import ../src/url.bend as Url
import ../laws/UrlFragmentHidesQuery.bend as Laws

def Laws.frag_first(_s, hier, _rest, e):
  %e : {Url.frag.drop.of(_) == hier : String}
  {==}

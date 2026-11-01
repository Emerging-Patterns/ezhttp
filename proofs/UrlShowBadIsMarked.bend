# proofs of laws/UrlShowBadIsMarked.bend
import Base
import ../laws/UrlShowBadIsMarked.bend as Laws
import ./lemmas/BaseEqualities.bend as M1

def Laws.url_show_bad_is_marked(why):
  M1.eq.starts_nil(why)

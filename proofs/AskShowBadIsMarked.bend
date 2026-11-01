# proofs of laws/AskShowBadIsMarked.bend
import Base
import ../laws/AskShowBadIsMarked.bend as Laws
import ./lemmas/BaseEqualities.bend as M1

def Laws.ask_show_bad_is_marked(why):
  M1.eq.starts_nil(why)

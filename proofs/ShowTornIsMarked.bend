# proofs of laws/ShowTornIsMarked.bend
import Base
import ../laws/ShowTornIsMarked.bend as Laws
import ./lemmas/BaseEqualities.bend as M1

def Laws.show_torn_is_marked(why):
  M1.eq.starts_nil(why)

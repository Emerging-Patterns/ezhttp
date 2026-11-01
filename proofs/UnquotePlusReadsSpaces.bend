# proofs of laws/UnquotePlusReadsSpaces.bend
import Base
import ../laws/UnquotePlusReadsSpaces.bend as Laws

def Laws.qs_unquote_plus(_s):
  {==}

def Laws.qs_byte_plus(c, e):
  %e : {Bool.pick(U32, Bool.and(True{}, _), 32, Char.to_u32(c)) == 32 : U32}
  {==}

# proofs of laws/PathFormKeepsSlash.bend
import Base
import ../src/pct.bend as Pct
import ../laws/PathFormKeepsSlash.bend as Laws

def Laws.path_keeps_slash(_rest):
  {==}

def Laws.component_escapes_slash(_rest):
  {==}

def Laws.component_is_path_elsewhere(c, e, rest):
  %e : {Pct.one.of(c, rest, Bool.or(Pct.unreserved(c), Bool.and(_, False{})))
    == Pct.one.of(c, rest, Bool.or(Pct.unreserved(c), Bool.and(_, True{})))
    : String}
  {==}

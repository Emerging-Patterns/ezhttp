# proofs of laws/QuoteKeepsUnreserved.bend
import Base
import ../src/pct.bend as Pct
import ../laws/QuoteKeepsUnreserved.bend as Laws

# --- percent-encoding ---

def Laws.quote_nil(_slash):
  {==}

def Laws.quote_cons(_slash, _c, _t):
  {==}

def Laws.one_unreserved(slash, c, e, rest):
  %e : {Pct.one.of(c, rest, Bool.or(_, Bool.and(U32.is_eq(c, 47), slash)))
    == SCon{Chr{c}, rest} : String}
  {==}

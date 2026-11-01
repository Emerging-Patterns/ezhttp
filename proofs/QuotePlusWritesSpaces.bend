# proofs of laws/QuotePlusWritesSpaces.bend
import Base
import ../src/pct.bend as Pct
import ../src/qs.bend as Qs
import ../laws/QuotePlusWritesSpaces.bend as Laws

def Laws.qs_qp_nil(_s, e):
  %e : {Qs.quote.plus(_) == "" : String}
  {==}

def Laws.qs_qp_space(_t):
  {==}

def Laws.qs_qp_other(cp, t, e):
  %e : {Qs.plus.one(cp, Qs.quote.plus(t), _)
    == Pct.one(False{}, cp, Qs.quote.plus(t)) : String}
  {==}

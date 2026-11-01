# For every string, `quote_plus` writes its characters in order, each
# independently of the others: a space as `+`, every other character as
# `quote_component` writes it (laws/QuoteKeepsUnreserved.bend to 3), so `+`
# is `%2B`; this is Python's `quote_plus(s)` (safe `""`).
import Base
import ../src/pct.bend as Pct
import ../src/qs.bend as Qs

# LAW: quote_plus writes nothing for the empty string
law qs_qp_nil:
  for s: String
  for e: {"" == s : String}
  {Qs.quote.plus(s) == "" : String}

# LAW: a space is written `+`
law qs_qp_space:
  for t: String
  {Qs.quote.plus(SCon{' ', t}) == SCon{'+', Qs.quote.plus(t)} : String}

# LAW: every other character is written as quote_component writes it
law qs_qp_other:
  for +cp: U32
  for t: String
  for e: {False{} == U32.is_eq(cp, 32) : Bool}
  {Qs.quote.plus(SCon{Chr{cp}, t}) == Pct.one(False{}, cp, Qs.quote.plus(t))
    : String}

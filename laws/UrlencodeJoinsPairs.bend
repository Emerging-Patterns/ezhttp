# For every list of pairs, `urlencode` writes each pair as
# `quote_plus(name)`, `=`, `quote_plus(value)`, in order, with `&` between
# two pairs and nothing for no pairs (WHATWG URL §5.2 serializer's shape,
# Python's `urlencode(pairs)` escaping).
import Base
import ../src/qs.bend as Qs

# LAW: no pairs are the empty query
law qs_ue_nil:
  for ps: List<&2, Qs.Kv()>
  for e: {[] == ps : List<&2, Qs.Kv()>}
  {Qs.urlencode(ps) == "" : String}

# LAW: the first pair, then the others each after `&`
law qs_ue_cons:
  for name: String
  for value: String
  for t: List<&2, Qs.Kv()>
  {Qs.urlencode((name, value) <> t) == Qs.form.pair(name, value)
    ++ Qs.form.more(t) : String}

# LAW: after the last pair, nothing
law qs_more_nil:
  for ps: List<&2, Qs.Kv()>
  for e: {[] == ps : List<&2, Qs.Kv()>}
  {Qs.form.more(ps) == "" : String}

# LAW: each pair after the first is written after `&`
law qs_more_cons:
  for name: String
  for value: String
  for t: List<&2, Qs.Kv()>
  {Qs.form.more((name, value) <> t)
    == "&" ++ Qs.form.pair(name, value) ++ Qs.form.more(t) : String}

# LAW: a pair is its quote_plus'd name, `=` and its quote_plus'd value
law qs_pair:
  for name: String
  for value: String
  {Qs.form.pair(name, value)
    == Qs.quote.plus(name) ++ "=" ++ Qs.quote.plus(value) : String}

# For every string, `parse_query` splits it on every `&` (WHATWG URL §5.1
# step 1), skips each empty piece (step 3.1), and reads every other piece in
# order as a pair: cut at its first `=`, the name is the text before it and
# the value the text after it; a piece with no `=` is a name with an empty
# value (step 3.2); both are `unquote_plus`'d (step 3.3, 3.4). A blank value
# is kept, and every pair is kept in order, duplicate names included.
#
# also rests on: laws/CutAtFirstEquals.bend, laws/SplitAtCharacter.bend
import Base
import ../src/qs.bend as Qs

# LAW (WHATWG URL §5.1 step 1): a query is split on every `&`
law qs_parse:
  for text: String
  {Qs.parse(text) == Qs.fields(String.split(text, '&'))
    : List<&2, Qs.Kv()>}

# LAW: no pieces, no pairs
law qs_fields_nil:
  for ps: List<&2, String>
  for e: {[] == ps : List<&2, String>}
  {Qs.fields(ps) == [] : List<&2, Qs.Kv()>}

# LAW (WHATWG URL §5.1 step 3.1): an empty piece is skipped
law qs_fields_skip:
  for t: List<&2, String>
  {Qs.fields("" <> t) == Qs.fields(t) : List<&2, Qs.Kv()>}

# LAW: any other piece is a pair, in front of the rest's, in order
law qs_fields_keep:
  for +p: String
  for t: List<&2, String>
  for e: {False{} == String.is_empty(p) : Bool}
  {Qs.fields(p <> t) == Qs.field(p) <> Qs.fields(t) : List<&2, Qs.Kv()>}

# LAW: a piece is read by where its first `=` is
law qs_field:
  for +piece: String
  {Qs.field(piece) == Qs.field.of(Qs.cut(piece), piece) : Qs.Kv()}

# LAW (WHATWG URL §5.1 step 3.2): a piece with no `=` is a name with an
# empty value
law qs_field_none:
  for whole: String
  {Qs.field.of(None{}, whole) == (Qs.unquote.plus(whole), "") : Qs.Kv()}

# LAW (WHATWG URL §5.1 steps 3.2 to 3.4): a piece cut at its first `=` is the
# name before it and the value after it, both unquote_plus'd
law qs_field_some:
  for name: String
  for value: String
  for whole: String
  {Qs.field.of(Some{(name, value)}, whole)
    == (Qs.unquote.plus(name), Qs.unquote.plus(value)) : Qs.Kv()}

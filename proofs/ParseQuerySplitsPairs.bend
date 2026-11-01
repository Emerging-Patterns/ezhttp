# proofs of laws/ParseQuerySplitsPairs.bend
import Base
import ../src/qs.bend as Qs
import ../laws/ParseQuerySplitsPairs.bend as Laws

def Laws.qs_parse(_text):
  {==}

def Laws.qs_fields_nil(_ps, e):
  %e : {Qs.fields(_) == [] : List<&2, Qs.Kv()>}
  {==}

def Laws.qs_fields_skip(_t):
  {==}

def Laws.qs_fields_keep(p, t, e):
  %e : {Qs.fields.put(p, Qs.fields(t), _) == Qs.field(p) <> Qs.fields(t)
    : List<&2, Qs.Kv()>}
  {==}

def Laws.qs_field(_piece):
  {==}

def Laws.qs_field_none(_whole):
  {==}

def Laws.qs_field_some(_name, _value, _whole):
  {==}

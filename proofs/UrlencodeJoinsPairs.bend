# proofs of laws/UrlencodeJoinsPairs.bend
import Base
import ../src/qs.bend as Qs
import ../laws/UrlencodeJoinsPairs.bend as Laws

def Laws.qs_ue_nil(_ps, e):
  %e : {Qs.urlencode(_) == "" : String}
  {==}

def Laws.qs_ue_cons(_name, _value, _t):
  {==}

def Laws.qs_more_nil(_ps, e):
  %e : {Qs.form.more(_) == "" : String}
  {==}

def Laws.qs_more_cons(_name, _value, _t):
  {==}

def Laws.qs_pair(_name, _value):
  {==}

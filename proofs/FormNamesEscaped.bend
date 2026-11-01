# proofs of laws/FormNamesEscaped.bend
import Base
import ../src/form.bend as Form
import ../laws/FormNamesEscaped.bend as Laws

def Laws.fq_nil(_s, e):
  %e : {Form.form.quote(_) == "" : String}
  {==}

def Laws.fq_cons(_c, _t):
  {==}

def Laws.fq_dq(_rest):
  {==}

def Laws.fq_cr(_rest):
  {==}

def Laws.fq_lf(_rest):
  {==}

def Laws.fq_other(c, e1, e2, e3, rest):
  %e1 : {Form.form.one.dq(c, rest, _) == SCon{Chr{c}, rest} : String}
  %e2 : {Form.form.one.cr(c, rest, _) == SCon{Chr{c}, rest} : String}
  %e3 : {Form.form.one.lf(c, rest, _) == SCon{Chr{c}, rest} : String}
  {==}

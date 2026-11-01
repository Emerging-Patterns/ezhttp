# proofs of laws/FormRefusesBadRequests.bend
import Base
import ../src/form.bend as Form
import ../laws/FormRefusesBadRequests.bend as Laws

def Laws.form_bad_boundary(b, ps, e):
  %e : {Form.form.check(b, ps, _)
    == Form.NoPlan{"the boundary must be 1 to 70 of A-Z a-z 0-9 - _ ."}
    : Form.Plan}
  {==}

def Laws.form_clash(b, ps, e1, e2):
  %e1 : {Form.form.check(b, ps, _)
    == Form.NoPlan{"the boundary occurs in a part's content"} : Form.Plan}
  %e2 : {Form.form.check.clash(b, ps, _)
    == Form.NoPlan{"the boundary occurs in a part's content"} : Form.Plan}
  {==}

def Laws.form_bad_type(b, ps, e1, e2, e3):
  %e1 : {Form.form.check(b, ps, _)
    == Form.NoPlan{"a file part's content type holds a CR or LF"} : Form.Plan}
  %e2 : {Form.form.check.clash(b, ps, _)
    == Form.NoPlan{"a file part's content type holds a CR or LF"} : Form.Plan}
  %e3 : {Form.form.check.type(b, ps, _)
    == Form.NoPlan{"a file part's content type holds a CR or LF"} : Form.Plan}
  {==}

def Laws.form_ok(b, ps, e1, e2, e3):
  %e1 : {Form.form.check(b, ps, _)
    == Form.Plan{Form.form.type(b), Form.form.parts(b, ps)}
    : Form.Plan}
  %e2 : {Form.form.check.clash(b, ps, _)
    == Form.Plan{Form.form.type(b), Form.form.parts(b, ps)}
    : Form.Plan}
  %e3 : {Form.form.check.type(b, ps, _)
    == Form.Plan{Form.form.type(b), Form.form.parts(b, ps)}
    : Form.Plan}
  {==}

def Laws.form_type(_b):
  {==}

# proofs of laws/FormBoundaryRules.bend
import Base
import ../src/form.bend as Form
import ../laws/FormBoundaryRules.bend as Laws

def Laws.all_step(ok, _rest):
  match ok:
    case False{}:
      {==}
    case True{}:
      {==}

def Laws.any_step(hit, _rest):
  match hit:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.boundary_ok(_b):
  {==}

def Laws.bchar(_cp):
  {==}

def Laws.bchars_nil(_s, e):
  %e : {Form.form.bchars(_) == True{} : Bool}
  {==}

def Laws.bchars_cons(c, t):
  Laws.all_step(Form.form.bchar(c), _u => Form.form.bchars(t))

def Laws.delim(_b):
  {==}

def Laws.clash_nil(_b):
  {==}

def Laws.clash_cons(b, p, t):
  Laws.any_step(Form.form.hit(b, p), _u => Form.form.clash(b, t))

def Laws.has_nil(_pat):
  {==}

def Laws.has_cons(x, t, pat):
  Laws.any_step(Form.octets.starts(x <> t, pat), _u => Form.octets.has(t, pat))

def Laws.starts_done(xs):
  match xs:
    case []:
      {==}
    case _x <> _t:
      {==}

def Laws.starts_short(_p, _q):
  {==}

def Laws.starts_cons(x, t, p, q):
  Laws.all_step(U32.is_eq(x, p), _u => Form.octets.starts(t, q))

def Laws.badtype_nil(_ps, e):
  %e : {Form.form.badtype(_) == False{} : Bool}
  {==}

def Laws.badtype_cons(p, t):
  Laws.any_step(Form.form.badtype.one(p), _u => Form.form.badtype(t))

def Laws.badtype_field(_name, _value):
  {==}

def Laws.badtype_file(_name, _filename, _ctype, _clash):
  {==}

def Laws.hit_field(_b, _name, _value):
  {==}

def Laws.hit_file(_b, _name, _filename, _ctype, _clash):
  {==}

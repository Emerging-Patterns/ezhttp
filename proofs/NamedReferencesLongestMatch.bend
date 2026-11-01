# proofs of laws/NamedReferencesLongestMatch.bend
import Base
import ../src/unescape.bend as Ref
import ../laws/NamedReferencesLongestMatch.bend as Laws

def Laws.ref_named(_s):
  {==}

def Laws.ref_named_none(_s):
  {==}

def Laws.ref_named_some(_name, _first, _second, _s):
  {==}

def Laws.ref_best_nil(_s, _sofar):
  {==}

def Laws.ref_best_cons(_r, _t, _s, _sofar):
  {==}

def Laws.ref_step(_sofar, _name, _first, _second, _s):
  {==}

def Laws.ref_hit_miss(_sofar, _r, _name):
  {==}

def Laws.ref_hit_take(_sofar, _r, _name):
  {==}

def Laws.ref_take_longer(_sofar, _r):
  {==}

def Laws.ref_take_keep(_sofar, _r):
  {==}

def Laws.ref_len_none(_m, e):
  %e : {Ref.best.len(_) == 0n : Nat}
  {==}

def Laws.ref_len_some(_name, _first, _second):
  {==}

def Laws.ref_chars_one(first, second, e):
  %e : {SCon{Chr{first}, Bool.pick(String, _, "", SCon{Chr{second}, ""})}
    == SCon{Chr{first}, ""} : String}
  {==}

def Laws.ref_chars_two(first, second, e):
  %e : {SCon{Chr{first}, Bool.pick(String, _, "", SCon{Chr{second}, ""})}
    == SCon{Chr{first}, SCon{Chr{second}, ""}} : String}
  {==}

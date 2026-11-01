# proofs of laws/NumericReferencesDecode.bend
import Base
import ../src/unescape.bend as Ref
import ../laws/NumericReferencesDecode.bend as Laws

def Laws.ref_code(_n):
  {==}

def Laws.ref_code_zero(n, e):
  %e : {Ref.code.zero(n, _) == SCon{Chr{65533}, ""} : String}
  {==}

def Laws.ref_code_cr(n, e1, e2):
  %e1 : {Ref.code.zero(n, _) == "\r" : String}
  %e2 : {Ref.code.cr(n, _) == "\r" : String}
  {==}

def Laws.ref_code_c1(n, e1, e2, e3):
  %e1 : {Ref.code.zero(n, _)
    == SCon{Chr{Ref.nth(Ref.w1252(), U32.to_nat(U32.sub(n, 128)))}, ""}
    : String}
  %e2 : {Ref.code.cr(n, _)
    == SCon{Chr{Ref.nth(Ref.w1252(), U32.to_nat(U32.sub(n, 128)))}, ""}
    : String}
  %e3 : {Ref.code.c1(n, _)
    == SCon{Chr{Ref.nth(Ref.w1252(), U32.to_nat(U32.sub(n, 128)))}, ""}
    : String}
  {==}

def Laws.ref_code_bad(n, e1, e2, e3, e4):
  %e1 : {Ref.code.zero(n, _) == SCon{Chr{65533}, ""} : String}
  %e2 : {Ref.code.cr(n, _) == SCon{Chr{65533}, ""} : String}
  %e3 : {Ref.code.c1(n, _) == SCon{Chr{65533}, ""} : String}
  %e4 : {Ref.code.range(n, _) == SCon{Chr{65533}, ""} : String}
  {==}

def Laws.ref_code_dropped(n, e1, e2, e3, e4, e5):
  %e1 : {Ref.code.zero(n, _) == "" : String}
  %e2 : {Ref.code.cr(n, _) == "" : String}
  %e3 : {Ref.code.c1(n, _) == "" : String}
  %e4 : {Ref.code.range(n, _) == "" : String}
  %e5 : {Ref.code.kept(n, _) == "" : String}
  {==}

def Laws.ref_code_kept(n, e1, e2, e3, e4, e5):
  %e1 : {Ref.code.zero(n, _) == SCon{Chr{n}, ""} : String}
  %e2 : {Ref.code.cr(n, _) == SCon{Chr{n}, ""} : String}
  %e3 : {Ref.code.c1(n, _) == SCon{Chr{n}, ""} : String}
  %e4 : {Ref.code.range(n, _) == SCon{Chr{n}, ""} : String}
  %e5 : {Ref.code.kept(n, _) == SCon{Chr{n}, ""} : String}
  {==}

def Laws.ref_dropped(_n):
  {==}

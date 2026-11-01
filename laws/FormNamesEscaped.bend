# For every name or filename, `q` writes its characters in order, each
# independently of the others: `"` as `%22`, CR as `%0D`, LF as `%0A` (RFC
# 7578 §4.2, as HTML's form submission encodes them), and every other
# character as itself.
import Base
import ../src/form.bend as Form

# LAW: the empty name is written as the empty string
law fq_nil:
  for s: String
  for e: {SNil{} == s : String}
  {Form.form.quote(s) == "" : String}

# LAW: a name is written one character at a time, the first character's
# writing followed by the rest's
law fq_cons:
  for +c: U32
  for t: String
  {Form.form.quote(SCon{Chr{c}, t}) == Form.form.one(c, Form.form.quote(t))
    : String}

# LAW (RFC 7578 §4.2): `"` is written as %22
law fq_dq:
  for rest: String
  {Form.form.one(34, rest) == "%22" ++ rest : String}

# LAW (RFC 7578 §4.2): CR is written as %0D
law fq_cr:
  for rest: String
  {Form.form.one(13, rest) == "%0D" ++ rest : String}

# LAW (RFC 7578 §4.2): LF is written as %0A
law fq_lf:
  for rest: String
  {Form.form.one(10, rest) == "%0A" ++ rest : String}

# LAW: every other character is written as itself
law fq_other:
  for +c: U32
  for e1: {False{} == U32.is_eq(c, 34) : Bool}
  for e2: {False{} == U32.is_eq(c, 13) : Bool}
  for e3: {False{} == U32.is_eq(c, 10) : Bool}
  for rest: String
  {Form.form.one(c, rest) == SCon{Chr{c}, rest} : String}

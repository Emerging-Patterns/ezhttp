# A boundary is valid exactly when it has 1 to 70 characters (RFC 2046
# §5.1.1), each `A`-`Z`, `a`-`z`, `0`-`9`, `-`, `_` or `.` (characters RFC
# 2046 allows in a boundary and RFC 9110 §5.6.2 in a token, so the parameter
# needs no quotes). The delimiter occurs in a field's content (its value as
# UTF-8 octets) exactly when the octets of `--b` appear in it as a
# contiguous run, anywhere; it occurs in a file's content exactly when
# `Bytes.find` finds the octets of `--b` in its bytes (trusted in
# src/wire.bend). A part's content type holds a CR or LF exactly when it is
# a file part whose content type contains one; a field part has none.
#
# also rests on: laws/FormPartHeaders.bend
import Base
import ../src/form.bend as Form

# LAW (RFC 2046 §5.1.1): a boundary is 1 to 70 boundary characters
law boundary_ok:
  for +b: String
  {Form.form.boundary.ok(b)
    == Bool.and(Bool.and(Bool.not(String.is_empty(b)),
      Nat.is_le(String.length(b), 70n)), Form.form.bchars(b)) : Bool}

# LAW: the boundary characters are A-Z, a-z, 0-9, `-`, `_` and `.`
law bchar:
  for +cp: U32
  {Form.form.bchar(cp)
    == Bool.or(Bool.and(U32.is_le(65, cp), U32.is_le(cp, 90)),
      Bool.or(Bool.and(U32.is_le(97, cp), U32.is_le(cp, 122)),
        Bool.or(Bool.and(U32.is_le(48, cp), U32.is_le(cp, 57)),
          Bool.or(U32.is_eq(cp, 45),
            Bool.or(U32.is_eq(cp, 95), U32.is_eq(cp, 46)))))) : Bool}

# LAW: the empty string has no character that is not a boundary character
law bchars_nil:
  for s: String
  for e: {SNil{} == s : String}
  {Form.form.bchars(s) == True{} : Bool}

# LAW: a string's characters are boundary characters exactly when its first
# is and the rest's are
law bchars_cons:
  for +c: U32
  for t: String
  {Form.form.bchars(SCon{Chr{c}, t})
    == Bool.and(Form.form.bchar(c), Form.form.bchars(t)) : Bool}

# LAW (RFC 2046 §5.1.1): the delimiter is `--` and the boundary, as octets
law delim:
  for b: String
  {Form.form.delim(b) == Form.octets.onto("--" ++ b, []) : List<&2, U32>}

# LAW: no parts, no clash
law clash_nil:
  for b: String
  {Form.form.clash(b, []) == False{} : Bool}

# LAW: a list of parts clashes exactly when its first part's content holds
# the delimiter or the rest clashes
law clash_cons:
  for +b: String
  for p: Form.Part
  for t: List<&2, Form.Part>
  {Form.form.clash(b, p <> t)
    == Bool.or(Form.form.hit(b, p), Form.form.clash(b, t)) : Bool}

# LAW: a field's content holds the delimiter exactly when its value's UTF-8
# octets hold the delimiter's octets as a contiguous run
law hit_field:
  for +b: String
  for name: String
  for value: String
  {Form.form.hit(b, Form.Field{name, value})
    == Form.octets.has(Form.octets.onto(value, []), Form.form.delim(b)) : Bool}

# LAW: a file's content holds the delimiter exactly when the search of its
# bytes found it
law hit_file:
  for +b: String
  for name: String
  for filename: String
  for ctype: String
  for clash: Bool
  {Form.form.hit(b, Form.File{name, filename, ctype, clash}) == clash : Bool}

# LAW: a check of this and the rest holds exactly when both do
law all_step:
  for ok: Bool
  for rest: Unit -> Bool
  {Form.all.step(ok, rest) == Bool.and(ok, rest(Unit{})) : Bool}

# LAW: a search of this and the rest hits exactly when either does
law any_step:
  for hit: Bool
  for rest: Unit -> Bool
  {Form.any.step(hit, rest) == Bool.or(hit, rest(Unit{})) : Bool}

# LAW: no octets hold a pattern exactly when the pattern is empty
law has_nil:
  for +pat: List<&2, U32>
  {Form.octets.has([], pat) == Form.octets.starts([], pat) : Bool}

# LAW: octets hold a pattern exactly when they open with it or their rest
# holds it
law has_cons:
  for +x: U32
  for +t: List<&2, U32>
  for +pat: List<&2, U32>
  {Form.octets.has(x <> t, pat)
    == Bool.or(Form.octets.starts(x <> t, pat), Form.octets.has(t, pat))
    : Bool}

# LAW: every octets open with the empty pattern
law starts_done:
  for xs: List<&2, U32>
  {Form.octets.starts(xs, []) == True{} : Bool}

# LAW: no octets open with a pattern that is not empty
law starts_short:
  for p: U32
  for q: List<&2, U32>
  {Form.octets.starts([], p <> q) == False{} : Bool}

# LAW: octets open with a pattern exactly when their first octets are equal
# and the rest opens with the pattern's rest
law starts_cons:
  for x: U32
  for t: List<&2, U32>
  for p: U32
  for q: List<&2, U32>
  {Form.octets.starts(x <> t, p <> q)
    == Bool.and(U32.is_eq(x, p), Form.octets.starts(t, q)) : Bool}

# LAW: no parts hold a bad content type
law badtype_nil:
  for ps: List<&2, Form.Part>
  for e: {[] == ps : List<&2, Form.Part>}
  {Form.form.badtype(ps) == False{} : Bool}

# LAW: a list of parts holds a bad content type exactly when its first part
# or its rest does
law badtype_cons:
  for p: Form.Part
  for t: List<&2, Form.Part>
  {Form.form.badtype(p <> t)
    == Bool.or(Form.form.badtype.one(p), Form.form.badtype(t)) : Bool}

# LAW: a field part has no content type to be bad
law badtype_field:
  for name: String
  for value: String
  {Form.form.badtype.one(Form.Field{name, value}) == False{} : Bool}

# LAW: a file part's content type is bad exactly when it holds a CR or an LF
law badtype_file:
  for name: String
  for filename: String
  for +ctype: String
  for clash: Bool
  {Form.form.badtype.one(Form.File{name, filename, ctype, clash})
    == Bool.or(String.contains(ctype, "\r"), String.contains(ctype, "\n"))
    : Bool}

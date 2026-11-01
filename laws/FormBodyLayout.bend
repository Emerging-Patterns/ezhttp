# For every valid boundary `b` and list of parts, the body is laid out, for
# each part in order, as `--b` CRLF, the part's header lines
# (laws/FormPartHeaders.bend), CRLF, the part's content (a field's value as
# octets; for a file, its bytes as they are, the next file's in the order
# the parts give), CRLF; then `--b--` CRLF (RFC 7578 §4.1, RFC 2046 §5.1.1);
# every text in it is written as its UTF-8 octets, character by character.
import Base
import ../src/pct.bend as Pct
import ../src/form.bend as Form

# LAW: a field's content is a run of its value's UTF-8 octets
law content_field:
  for name: String
  for value: String
  for rest: List<&2, Form.Seg>
  {Form.form.content(Form.Field{name, value}, rest)
    == Form.Run{Form.octets.onto(value, [])} <> rest : List<&2, Form.Seg>}

# LAW: a file's content is the next file's bytes, unchanged
law content_file:
  for name: String
  for filename: String
  for ctype: String
  for clash: Bool
  for rest: List<&2, Form.Seg>
  {Form.form.content(Form.File{name, filename, ctype, clash}, rest)
    == Form.Blob{} <> rest : List<&2, Form.Seg>}

# LAW (RFC 2046 §5.1.1): after the last part comes the close delimiter
law parts_nil:
  for +b: String
  {Form.form.parts(b, []) == [Form.Run{Form.octets.onto("--" ++ b ++ "--\r\n", [])}]
    : List<&2, Form.Seg>}

# LAW: the parts are written in order, each in front of the rest
law parts_cons:
  for +b: String
  for p: Form.Part
  for t: List<&2, Form.Part>
  {Form.form.parts(b, p <> t) == Form.form.part(b, p, Form.form.parts(b, t))
    : List<&2, Form.Seg>}

# LAW (RFC 7578 §4.1): a part is the delimiter line, its header lines, a blank
# line, its content and a CRLF
law part:
  for +b: String
  for +p: Form.Part
  for rest: List<&2, Form.Seg>
  {Form.form.part(b, p, rest)
    == Form.Run{Form.octets.onto("--" ++ b ++ "\r\n" ++ Form.form.head(p)
      ++ "\r\n", [])} <> Form.form.content(p,
        Form.Run{Form.octets.onto("\r\n", [])} <> rest) : List<&2, Form.Seg>}

# LAW: the empty string writes no octets
law onto_nil:
  for rest: List<&2, U32>
  {Form.octets.onto("", rest) == rest : List<&2, U32>}

# LAW (RFC 3629 §3): a string is written as its first character's UTF-8
# octets, then the rest's
law onto_cons:
  for +c: U32
  for t: String
  for rest: List<&2, U32>
  {Form.octets.onto(SCon{Chr{c}, t}, rest)
    == List.append(&2, U32, Pct.utf8(c), Form.octets.onto(t, rest))
    : List<&2, U32>}

# A field part named `n` (`form_field(n, v)`) has exactly the header line
# `Content-Disposition: form-data; name="<q(n)>"`; a file part
# (`form_file(n, f, t, bytes)`, `bytes` packed `Bytes`) has exactly
# `Content-Disposition: form-data; name="<q(n)>"; filename="<q(f)>"` and
# `Content-Type: <t>` (RFC 7578 §4.2, §4.4), each line ended by CRLF, `q` as
# laws/FormNamesEscaped.bend writes it.
import Base
import ../src/form.bend as Form
import bend-kit-bytes@0.3.2.0/bytes.bend as Bytes

# LAW: form_field makes a field part
law field_is:
  for +d: String
  for name: String
  for value: String
  {Pair.fst(List<&2, Form.Part>, List<&1, Bytes.Bytes>,
    Form.form.split(d, [Form.form.field(name, value)]))
    == [Form.Field{name, value}] : List<&2, Form.Part>}

# LAW: a file part is planned with its names, its content type and whether
# the search of its bytes found the delimiter
law file_is:
  for name: String
  for filename: String
  for ctype: String
  for n: U32
  for buf: Array<U32>
  for hit: Bool
  {Pair.fst(List<&2, Form.Part>, List<&1, Bytes.Bytes>,
    Form.form.split.file(name, filename, ctype, (Bytes.Bytes{n, buf}, hit),
      ([], [])))
    == [Form.File{name, filename, ctype, hit}] : List<&2, Form.Part>}

# LAW (RFC 7578 §4.2): a field part's header is its Content-Disposition line
law head_field:
  for name: String
  for value: String
  {Form.form.head(Form.Field{name, value})
    == Form.form.disposition(name) ++ "\r\n" : String}

# LAW (RFC 7578 §4.2, §4.4): a file part's header is its Content-Disposition
# line with the filename, then its Content-Type line
law head_file:
  for name: String
  for filename: String
  for ctype: String
  for clash: Bool
  {Form.form.head(Form.File{name, filename, ctype, clash})
    == Form.form.disposition(name) ++ "; filename=\"" ++ Form.form.quote(filename)
      ++ "\"\r\n" ++ "Content-Type: " ++ ctype ++ "\r\n" : String}

# LAW (RFC 7578 §4.2): the disposition names the part, quoted
law disposition:
  for name: String
  {Form.form.disposition(name)
    == "Content-Disposition: form-data; name=\"" ++ Form.form.quote(name)
      ++ "\"" : String}

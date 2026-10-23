# ezhttp/src/form: multipart/form-data request bodies (RFC 7578), no IO. A
# form is text fields and file parts whose content is packed Bytes. Every
# decision is form.plan's, over the parts with each file's content replaced
# by whether the delimiter occurs in it; the plan lays the body out as runs
# of octets and file contents, and form.build puts them together, so a
# file's bytes reach the wire unchanged (SPEC.md HTTP-CLI-10). The caller
# picks the boundary and the builder refuses one a reader could misread.
# SPEC.md HTTP-FORM lists what is guaranteed.
import Base
import bend-kit-bytes@0.3.2.0/bytes.bend as Bytes
import ./body.bend as Body
import ./pct.bend as Pct

# one part handed to the builder: a text field, or a file with its name,
# content type and bytes
type Upload is Type:
  UField{name: String, value: String}
  UFile{name: String, filename: String, ctype: String, bytes: Bytes.Bytes}

# one part as the plan sees it: a text field, or a file whose content is
# known only by whether the delimiter occurs in it
type Part is Data:
  Field{name: String, value: String}
  File{name: String, filename: String, ctype: String, clash: Bool}

# one run of the body the plan lays out: octets, or the next file's bytes
type Seg is Data:
  Run{octets: List<&2, U32>}
  Blob{}

# a planned form (the Content-Type field value and the body's runs), or why
# not
type Plan is Data:
  NoPlan{why: String}
  Plan{ctype: String, segs: List<&2, Seg>}

# a built form (the Content-Type field value and the body), or why not
type Form is Type:  # noqa: L001 it holds Bytes, which no law can compare; form.plan's laws cover it (HTTP-TRUST-8)
  NoForm{why: String}
  Form{ctype: String, body: Body.Body}

# a text field
def form.field(name: String, value: String) -> Upload:
  UField{name, value}

# a file part: its field name, its filename, its content type and its bytes
def form.file(name: String, filename: String, ctype: String,
  bytes: Bytes.Bytes) -> Upload:
  UFile{name, filename, ctype, bytes}

# --- octets ---

# a string's UTF-8 octets in front of `rest` (RFC 3629 §3)
def octets.onto(s: String, rest: List<&2, U32>) -> List<&2, U32>:
  match s:
    case SNil{}:
      rest
    case SCon{Chr{+cp}, tail}:
      List.append(&2, U32, Pct.utf8(cp), octets.onto(tail, rest))

# a check that holds when this does and the rest does: a false ends it
def all.step(ok: Bool, rest: Unit -> Bool) -> Bool:
  match ok:
    case False{}:
      False{}
    case True{}:
      rest(Unit{})

# a search that hits when this does or the rest does: a true ends it
def any.step(hit: Bool, rest: Unit -> Bool) -> Bool:
  match hit:
    case True{}:
      True{}
    case False{}:
      rest(Unit{})

# whether octets open with a pattern's octets
def octets.starts(xs: List<&2, U32>, pat: List<&2, U32>) -> Bool:
  match xs pat:
    case Nil{} Nil{}:
      True{}
    case Nil{} Con{p, q}:
      False{}
    case Con{x, t} Nil{}:
      True{}
    case Con{x, t} Con{p, q}:
      all.step(U32.is_eq(x, p), _u => octets.starts(t, q))

# whether a pattern's octets occur as a contiguous run anywhere in octets
def octets.has(xs: List<&2, U32>, +pat: List<&2, U32>) -> Bool:
  match xs:
    case []:
      octets.starts([], pat)
    case +x <> +t:
      any.step(octets.starts(x <> t, pat), _u => octets.has(t, pat))

# --- the boundary (RFC 2046 §5.1.1) ---

# a boundary character this builder allows: A-Z a-z 0-9 - _ . (each a bchar
# of RFC 2046 and a tchar of RFC 9110 §5.6.2, so no quotes are needed)
def form.bchar(+cp: U32) -> Bool:
  Bool.or(Bool.and(U32.is_le(65, cp), U32.is_le(cp, 90)),
    Bool.or(Bool.and(U32.is_le(97, cp), U32.is_le(cp, 122)),
      Bool.or(Bool.and(U32.is_le(48, cp), U32.is_le(cp, 57)),
        Bool.or(U32.is_eq(cp, 45),
          Bool.or(U32.is_eq(cp, 95), U32.is_eq(cp, 46))))))

# every character of a string is a boundary character
def form.bchars(s: String) -> Bool:
  match s:
    case SNil{}:
      True{}
    case SCon{Chr{+cp}, tail}:
      all.step(form.bchar(cp), _u => form.bchars(tail))

# a boundary is 1 to 70 boundary characters
def form.boundary.ok(+b: String) -> Bool:
  Bool.and(Bool.and(Bool.not(String.is_empty(b)),
    Nat.is_le(String.length(b), 70n)), form.bchars(b))

# the delimiter a reader looks for: "--" and the boundary, as octets
def form.delim(b: String) -> List<&2, U32>:
  octets.onto("--" ++ b, [])

# --- quoting (RFC 7578 §4.2) ---

# a character that is not `"` or CR: LF as %0A, anything else as itself
def form.one.lf(+cp: U32, rest: String, lf: Bool) -> String:
  match lf:
    case True{}:
      "%0A" ++ rest
    case False{}:
      SCon{Chr{cp}, rest}

# a character that is not `"`: CR as %0D, else on to LF
def form.one.cr(+cp: U32, rest: String, cr: Bool) -> String:
  match cr:
    case True{}:
      "%0D" ++ rest
    case False{}:
      form.one.lf(cp, rest, U32.is_eq(cp, 10))

# a character of a quoted name, once it is known whether it is `"`: as %22
def form.one.dq(+cp: U32, rest: String, dq: Bool) -> String:
  match dq:
    case True{}:
      "%22" ++ rest
    case False{}:
      form.one.cr(cp, rest, U32.is_eq(cp, 13))

# one character of a quoted name, followed by `rest`
def form.one(+cp: U32, rest: String) -> String:
  form.one.dq(cp, rest, U32.is_eq(cp, 34))

# a name or filename as the inside of its quoted-string, as HTML's form
# submission writes it: `"`, CR and LF percent-encoded, the rest as itself
def form.quote(s: String) -> String:
  match s:
    case SNil{}:
      SNil{}
    case SCon{Chr{+cp}, tail}:
      form.one(cp, form.quote(tail))

# --- the parts (RFC 7578 §4) ---

# the Content-Disposition line's text up to its name parameter's end
def form.disposition(name: String) -> String:
  "Content-Disposition: form-data; name=\"" ++ form.quote(name) ++ "\""

# a part's header lines, each ended by CRLF (RFC 7578 §4.2, §4.4)
def form.head(p: Part) -> String:
  match p:
    case Field{name, value}:
      form.disposition(name) ++ "\r\n"
    case File{name, filename, ctype, clash}:
      form.disposition(name) ++ "; filename=\"" ++ form.quote(filename) ++ "\"\r\n"
        ++ "Content-Type: " ++ ctype ++ "\r\n"

# a part's content in front of `rest`: a field's value as UTF-8 octets, a
# file's bytes as they are
def form.content(p: Part, rest: List<&2, Seg>) -> List<&2, Seg>:
  match p:
    case Field{name, value}:
      Run{octets.onto(value, [])} <> rest
    case File{name, filename, ctype, clash}:
      Blob{} <> rest

# one part in front of `rest`: the delimiter line, its head, a blank line,
# its content and a CRLF
def form.part(+b: String, +p: Part, rest: List<&2, Seg>) -> List<&2, Seg>:
  Run{octets.onto("--" ++ b ++ "\r\n" ++ form.head(p) ++ "\r\n", [])}
    <> form.content(p, Run{octets.onto("\r\n", [])} <> rest)

# every part in order, then the close delimiter (RFC 2046 §5.1.1)
def form.parts(+b: String, ps: List<&2, Part>) -> List<&2, Seg>:
  match ps:
    case []:
      [Run{octets.onto("--" ++ b ++ "--\r\n", [])}]
    case p <> t:
      form.part(b, p, form.parts(b, t))

# --- the checks ---

# whether a part's content holds the delimiter: a field's octets are
# searched, a file's answer was found in its bytes
def form.hit(+b: String, p: Part) -> Bool:
  match p:
    case Field{name, value}:
      octets.has(octets.onto(value, []), form.delim(b))
    case File{name, filename, ctype, clash}:
      clash

# whether some part's content holds the delimiter
def form.clash(+b: String, ps: List<&2, Part>) -> Bool:
  match ps:
    case []:
      False{}
    case p <> t:
      any.step(form.hit(b, p), _u => form.clash(b, t))

# whether a part's content type holds a CR or an LF
def form.badtype.one(p: Part) -> Bool:
  match p:
    case Field{name, value}:
      False{}
    case File{name, filename, +ctype, clash}:
      Bool.or(String.contains(ctype, "\r"), String.contains(ctype, "\n"))

# whether any part's content type holds a CR or an LF
def form.badtype(ps: List<&2, Part>) -> Bool:
  match ps:
    case []:
      False{}
    case p <> t:
      any.step(form.badtype.one(p), _u => form.badtype(t))

# the Content-Type field value of a form with this boundary (RFC 7578 §4.1)
def form.type(b: String) -> String:
  "multipart/form-data; boundary=" ++ b

# the plan once its content types are checked
def form.check.type(+b: String, ps: List<&2, Part>, bad: Bool) -> Plan:
  match bad:
    case True{}:
      NoPlan{"a file part's content type holds a CR or LF"}
    case False{}:
      Plan{form.type(b), form.parts(b, ps)}

# the plan once its parts are checked against the delimiter
def form.check.clash(+b: String, +ps: List<&2, Part>, hit: Bool) -> Plan:
  match hit:
    case True{}:
      NoPlan{"the boundary occurs in a part's content"}
    case False{}:
      form.check.type(b, ps, form.badtype(ps))

# the plan once its boundary is checked
def form.check(+b: String, +ps: List<&2, Part>, ok: Bool) -> Plan:
  match ok:
    case False{}:
      NoPlan{"the boundary must be 1 to 70 of A-Z a-z 0-9 - _ ."}
    case True{}:
      form.check.clash(b, ps, form.clash(b, ps))

# a multipart/form-data body's plan with this boundary and these parts, or
# why not (SPEC.md HTTP-FORM)
def form.plan(+b: String, ps: List<&2, Part>) -> Plan:
  form.check(b, ps, form.boundary.ok(b))

# --- the body (SPEC.md HTTP-TRUST-8) ---

# whether a search found the delimiter, with the bytes handed back
def form.found(r: Bytes.Bytes & Maybe<&2, U32>) -> Bytes.Bytes & Bool:
  (bs, m) = r
  match m:
    case None{}:
      (bs, False{})
    case Some{i}:
      (bs, True{})

# a file part once its bytes are searched: the part the plan sees, onto the
# rest, and its bytes kept in order
def form.split.file(name: String, filename: String, ctype: String,
  r: Bytes.Bytes & Bool, rest: List<&2, Part> & List<&1, Bytes.Bytes>)
  -> List<&2, Part> & List<&1, Bytes.Bytes>:
  (bs, hit) = r
  (ps, fs) = rest
  (File{name, filename, ctype, hit} <> ps, bs <> fs)

# a field part onto the rest
def form.split.field(name: String, value: String,
  rest: List<&2, Part> & List<&1, Bytes.Bytes>)
  -> List<&2, Part> & List<&1, Bytes.Bytes>:
  (ps, fs) = rest
  (Field{name, value} <> ps, fs)

# the parts as the plan sees them, and the files' bytes in order; `d` is
# the delimiter's octets, one character each
def form.split(+d: String, us: List<&1, Upload>)
  -> List<&2, Part> & List<&1, Bytes.Bytes>:
  match us:
    case []:
      ([], [])
    case u <> t:
      match u:
        case UField{name, value}:
          form.split.field(name, value, form.split(d, t))
        case UFile{name, filename, ctype, bytes}:
          form.split.file(name, filename, ctype,
            form.found(Bytes.find(bytes, d)), form.split(d, t))

# the body's runs as packed octets, each file's bytes in its place
def form.runs(segs: List<&2, Seg>, fs: List<&1, Bytes.Bytes>)
  -> List<&1, Bytes.Bytes>:
  match segs:
    case []:
      []
    case Run{octets} <> t:
      Bytes.from_string(Body.octets.chars(octets)) <> form.runs(t, fs)
    case Blob{} <> t:
      match fs:
        case []:
          form.runs(t, [])
        case f <> rest:
          f <> form.runs(t, rest)

# a plan as the form it builds
def form.build(p: Plan, fs: List<&1, Bytes.Bytes>) -> Form:
  match p:
    case NoPlan{why}:
      NoForm{why}
    case Plan{ctype, segs}:
      Form{ctype, Body.Octets{Bytes.concat(form.runs(segs, fs))}}

# a planned form once the files are searched
def form.built(+b: String, r: List<&2, Part> & List<&1, Bytes.Bytes>) -> Form:
  (ps, fs) = r
  form.build(form.plan(b, ps), fs)

# a multipart/form-data body with this boundary and these parts, or why not
# (SPEC.md HTTP-FORM, HTTP-TRUST-8)
def form.body(+b: String, us: List<&1, Upload>) -> Form:
  form.built(b, form.split(Body.octets.chars(form.delim(b)), us))

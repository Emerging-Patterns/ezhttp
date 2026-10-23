# ezhttp/src/form: multipart/form-data request bodies (RFC 7578), pure. A
# form is text fields and file parts; the body is octets (Body.Octets), so a
# file's bytes reach the wire unchanged (SPEC.md HTTP-CLI-10). The caller picks
# the boundary and the builder refuses one a reader could misread. SPEC.md
# HTTP-FORM lists what is guaranteed.
import Base
import ./body.bend as Body
import ./pct.bend as Pct

# one part of a form: a text field, or a file with its name and content type
type Part is Data:
  Field{name: String, value: String}
  File{name: String, filename: String, ctype: String, bytes: List<&2, U32>}

# a built form (the Content-Type field value and the body), or why not
type Form is Data:
  NoForm{why: String}
  Form{ctype: String, body: Body.Body}

# a text field
def form.field(name: String, value: String) -> Part:
  Field{name, value}

# a file part: its field name, its filename, its content type and its bytes
# (each 0..255)
def form.file(name: String, filename: String, ctype: String,
  bytes: List<&2, U32>) -> Part:
  File{name, filename, ctype, bytes}

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
    case File{name, filename, ctype, bytes}:
      form.disposition(name) ++ "; filename=\"" ++ form.quote(filename) ++ "\"\r\n"
        ++ "Content-Type: " ++ ctype ++ "\r\n"

# a part's content in front of `rest`: a field's value as UTF-8, a file's
# bytes as they are
def form.content(p: Part, rest: List<&2, U32>) -> List<&2, U32>:
  match p:
    case Field{name, value}:
      octets.onto(value, rest)
    case File{name, filename, ctype, bytes}:
      List.append(&2, U32, bytes, rest)

# one part in front of `rest`: the delimiter line, its head, a blank line,
# its content and a CRLF
def form.part(+b: String, +p: Part, rest: List<&2, U32>) -> List<&2, U32>:
  octets.onto("--" ++ b ++ "\r\n" ++ form.head(p) ++ "\r\n",
    form.content(p, octets.onto("\r\n", rest)))

# every part in order, then the close delimiter (RFC 2046 §5.1.1)
def form.parts(+b: String, ps: List<&2, Part>) -> List<&2, U32>:
  match ps:
    case []:
      octets.onto("--" ++ b ++ "--\r\n", [])
    case p <> t:
      form.part(b, p, form.parts(b, t))

# --- the checks ---

# whether some part's content holds the delimiter
def form.clash(+b: String, ps: List<&2, Part>) -> Bool:
  match ps:
    case []:
      False{}
    case p <> t:
      any.step(octets.has(form.content(p, []), form.delim(b)),
        _u => form.clash(b, t))

# whether a part's content type holds a CR or an LF
def form.badtype.one(p: Part) -> Bool:
  match p:
    case Field{name, value}:
      False{}
    case File{name, filename, +ctype, bytes}:
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

# the form once its content types are checked
def form.check.type(+b: String, ps: List<&2, Part>, bad: Bool) -> Form:
  match bad:
    case True{}:
      NoForm{"a file part's content type holds a CR or LF"}
    case False{}:
      Form{form.type(b), Body.Octets{form.parts(b, ps)}}

# the form once its parts are checked against the delimiter
def form.check.clash(+b: String, +ps: List<&2, Part>, hit: Bool) -> Form:
  match hit:
    case True{}:
      NoForm{"the boundary occurs in a part's content"}
    case False{}:
      form.check.type(b, ps, form.badtype(ps))

# the form once its boundary is checked
def form.check(+b: String, +ps: List<&2, Part>, ok: Bool) -> Form:
  match ok:
    case False{}:
      NoForm{"the boundary must be 1 to 70 of A-Z a-z 0-9 - _ ."}
    case True{}:
      form.check.clash(b, ps, form.clash(b, ps))

# a multipart/form-data body with this boundary and these parts, or why not
# (SPEC.md HTTP-FORM)
def form.body(+b: String, ps: List<&2, Part>) -> Form:
  form.check(b, ps, form.boundary.ok(b))

# ezhttp/src/body: request entity as empty, UTF-8 text, or packed octets
# (bend-kit-bytes). Core does not depend on ezjson. Callers plug
# encode/decode through Bend type parameters (BYO JSON or any other
# representation).
import Base
import bend-kit-bytes@0.3.2.0/bytes.bend as Bytes

# what rides in a request: nothing, text, or raw octets
type Body is Type:
  Empty{}
  Plain{text: String}
  Octets{bytes: Bytes.Bytes}

# what the request text needs to know of a body: its text, or how many
# octets follow it (SPEC.md HTTP-CLI-10)
type Shape is Data:
  ShapeText{text: String}
  ShapeOctets{n: U32}

# an octets body's count: its shape, and the octets handed back
def body.sized(r: Bytes.Bytes & U32) -> Shape & Bytes.Bytes:
  (b, +n) = r
  (ShapeOctets{n}, b)

# a body as its shape and the octets sent after the request text: a text
# body's are none, and the empty body is the empty text
def body.shape(b: Body) -> Shape & Bytes.Bytes:
  match b:
    case Empty{}:
      (ShapeText{""}, Bytes.new(0))
    case Plain{text}:
      (ShapeText{text}, Bytes.new(0))
    case Octets{bytes}:
      body.sized(Bytes.length(bytes))

# octets, one character each (each 0..255), from a list of their values
def octets.chars(bs: List<&2, U32>) -> String:
  match bs:
    case []:
      ""
    case h <> t:
      SCon{Char.from_u32(h), octets.chars(t)}

# empty body
def body.empty() -> Body:
  Empty{}

# UTF-8 text body
def body.text(s: String) -> Body:
  Plain{s}

# octets body
def body.octets(bytes: Bytes.Bytes) -> Body:
  Octets{bytes}

# an octets body from a list of octet values (each 0..255; a value past 255
# keeps its low 8 bits)
def body.list(bs: List<&2, U32>) -> Body:
  Octets{Bytes.from_string(octets.chars(bs))}

# BYO encode: any value to a text body via the caller's encoder
def body.encode(~A: Data, ~to_text: A -> String, value: A) -> Body:
  Plain{to_text(value)}

# BYO decode: body text to a value via the caller's decoder
def body.decode(~A: Data, ~from_text: String -> Maybe<&2, A>, s: String)
  -> Maybe<&2, A>:
  from_text(s)

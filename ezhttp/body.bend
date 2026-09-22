# ezhttp/body: request entity as empty, UTF-8 text, or octet list. Core does
# not depend on ezjson. Callers plug encode/decode through Bend type
# parameters (BYO JSON or any other representation).
import Base

# what rides in a request: nothing, text, or raw octets (each U32 is 0..255)
type Body is Data:
  Empty{}
  Text{text: String}
  Octets{bytes: List<&2, U32>}

# one octet as a character whose code point is that byte
def octet.char(+b: U32) -> Char:
  Char.from_u32(b)

# octets as a string of those code points (wire UTF-8 length is utf8.len)
def octets.chars(bs: List<&2, U32>) -> String:
  match bs:
    case []:
      ""
    case h <> t:
      SCon{octet.char(h), octets.chars(t)}

# the payload bytes as a Bend string for the request line/body
def body.payload(b: Body) -> String:
  match b:
    case Empty{}:
      ""
    case Text{text}:
      text
    case Octets{bytes}:
      octets.chars(bytes)

# empty body
def body.empty() -> Body:
  Empty{}

# UTF-8 text body
def body.text(s: String) -> Body:
  Text{s}

# octet body (each element a wire-oriented code point 0..255)
def body.octets(bs: List<&2, U32>) -> Body:
  Octets{bs}

# BYO encode: any value to a text body via the caller's encoder
def body.encode(~A: Data, ~to_text: A -> String, value: A) -> Body:
  Text{to_text(value)}

# BYO decode: body text to a value via the caller's decoder
def body.decode(~A: Data, ~from_text: String -> Maybe<&2, A>, s: String)
  -> Maybe<&2, A>:
  from_text(s)

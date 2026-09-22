# ezhttp/b64: Base64 encoding for HTTP credentials (RFC 4648 §4). The
# alphabet is the standard table, with `=` padding. Decoding is not required
# for the Authorization helpers.
import Base

# how many octets of the current quantum are still missing
type Phase is Data:
  Need3{}
  Need2{first: U32}
  Need1{first: U32, second: U32}

# RFC 4648 §4 alphabet, index 0 is `A`
def b64.table() -> String:
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

# the character at a 0..63 index, `A` when the index is out of the table
def b64.char(m: Maybe<&2, Char>) -> Char:
  match m:
    case None{}:
      'A'
    case Some{c}:
      c

# one 6-bit value as an alphabet character
def b64.at(+n: U32) -> Char:
  b64.char(String.get(b64.table(), U32.to_nat(U32.and(n, 63))))

# 24 bits from three octets
def b64.pack(+a: U32, +b: U32, +c: U32) -> U32:
  U32.or(U32.or(U32.shln(a, 16n), U32.shln(b, 8n)), c)

# the last two characters when the quantum was short
def b64.tail.more(+n: U32, left: Nat) -> String:
  match left:
    case 0n:
      SCon{b64.at(U32.shrn(n, 6n)), SCon{'=', SNil{}}}
    case 1n+k:
      SCon{'=', SCon{'=', SNil{}}}

# four characters from a packed quantum; pad is how many `=` to write
def b64.tail(+n: U32, pad: Nat) -> String:
  match pad:
    case 0n:
      SCon{b64.at(U32.shrn(n, 6n)), SCon{b64.at(n), SNil{}}}
    case 1n+p:
      b64.tail.more(n, p)

# one quantum as four characters
def b64.quad(+a: U32, +b: U32, +c: U32, pad: Nat) -> String:
  +n = b64.pack(a, b, c)
  SCon{b64.at(U32.shrn(n, 18n)), SCon{b64.at(U32.shrn(n, 12n)), b64.tail(n, pad)}}

# padding for a quantum that ended early
def b64.end(phase: Phase) -> String:
  match phase:
    case Need3{}:
      ""
    case Need2{first}:
      b64.quad(first, 0, 0, 2n)
    case Need1{first, second}:
      b64.quad(first, second, 0, 1n)

# octets to Base64, three at a time (RFC 4648 §4)
def b64.go(bs: List<&2, U32>, phase: Phase) -> String:
  match bs:
    case []:
      b64.end(phase)
    case h <> t:
      match phase:
        case Need3{}:
          b64.go(t, Need2{h})
        case Need2{first}:
          b64.go(t, Need1{first, h})
        case Need1{first, second}:
          b64.quad(first, second, h, 0n) ++ b64.go(t, Need3{})

# code points of a string, one octet each (credentials are ASCII)
def b64.bytes(s: String) -> List<&2, U32>:
  match s:
    case SNil{}:
      []
    case SCon{h, t}:
      Char.to_u32(h) <> b64.bytes(t)

# Base64 of a string (RFC 4648 §4)
def b64.encode(s: String) -> String:
  b64.go(b64.bytes(s), Need3{})

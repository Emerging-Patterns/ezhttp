# For every string, Base64 (`b64.encode`, RFC 4648 §4) writes each group of
# three octets as the four alphabet characters of its 24 bits and goes on
# with the rest; a final group of two octets is three characters and one
# `=`, a final group of one octet is two characters and `==`; and the
# encoding is empty exactly when the input is. The RFC 4648 §10 test vectors
# (`f` is `Zg==`, `fo` is `Zm8=`, `foo` is `Zm9v`) and `user:pass` as
# `dXNlcjpwYXNz` are instances.
import Base
import ../src/b64.bend as B64

# LAW (RFC 4648 §4): three octets are one full quantum, then the rest
law b64_three:
  for +a: Char
  for +b: Char
  for +c: Char
  for s: String
  {B64.b64.encode(SCon{a, SCon{b, SCon{c, s}}})
    == B64.b64.quad(Char.to_u32(a), Char.to_u32(b), Char.to_u32(c), 0n)
      ++ B64.b64.encode(s) : String}

# LAW (RFC 4648 §4): two final octets are three characters and one `=`
law b64_two:
  for +a: Char
  for +b: Char
  {B64.b64.encode(SCon{a, SCon{b, SNil{}}})
    == B64.b64.quad(Char.to_u32(a), Char.to_u32(b), 0, 1n) : String}

# LAW (RFC 4648 §4): one final octet is two characters and `==`
law b64_one:
  for +a: Char
  {B64.b64.encode(SCon{a, SNil{}}) == B64.b64.quad(Char.to_u32(a), 0, 0, 2n)
    : String}

# LAW (RFC 4648 §4): the encoding is empty exactly when the input is
law b64_empty:
  for s: String
  {String.is_empty(B64.b64.encode(s)) == String.is_empty(s) : Bool}

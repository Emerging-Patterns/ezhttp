# For every hex reading so far `acc` and text `t` after the digit, the
# chunk-size reader (`hex.go`) reads each letter digit `a` to `f` exactly as
# its capital `A` to `F` (RFC 9112 §7.1: chunk-size is HEXDIG, and RFC 5234
# §2.3 makes its letters case-insensitive).
import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §7.1): `a` and `A` are the same chunk-size digit
law hex_a:
  for +acc: Nat
  for t: String
  {Http.hex.go(SCon{'a', t}, acc) == Http.hex.go(SCon{'A', t}, acc) : Nat}

# LAW (RFC 9112 §7.1): `b` and `B` are the same chunk-size digit
law hex_b:
  for +acc: Nat
  for t: String
  {Http.hex.go(SCon{'b', t}, acc) == Http.hex.go(SCon{'B', t}, acc) : Nat}

# LAW (RFC 9112 §7.1): `c` and `C` are the same chunk-size digit
law hex_c:
  for +acc: Nat
  for t: String
  {Http.hex.go(SCon{'c', t}, acc) == Http.hex.go(SCon{'C', t}, acc) : Nat}

# LAW (RFC 9112 §7.1): `d` and `D` are the same chunk-size digit
law hex_d:
  for +acc: Nat
  for t: String
  {Http.hex.go(SCon{'d', t}, acc) == Http.hex.go(SCon{'D', t}, acc) : Nat}

# LAW (RFC 9112 §7.1): `e` and `E` are the same chunk-size digit
law hex_e:
  for +acc: Nat
  for t: String
  {Http.hex.go(SCon{'e', t}, acc) == Http.hex.go(SCon{'E', t}, acc) : Nat}

# LAW (RFC 9112 §7.1): `f` and `F` are the same chunk-size digit
law hex_f:
  for +acc: Nat
  for t: String
  {Http.hex.go(SCon{'f', t}, acc) == Http.hex.go(SCon{'F', t}, acc) : Nat}

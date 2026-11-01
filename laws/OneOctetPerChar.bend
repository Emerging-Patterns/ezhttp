# What the client and the server receive is octets. The server turns each
# receive into text, one character per octet, by `Bytes.to_string` (trusted
# in src/wire.bend); the client keeps a response's octets packed, and turns
# into text only a receive it must judge by its text
# (laws/ReadsJudgedByCount.bend), its heads and its chunk-size lines
# (trusted in src/packed.bend). The octet walks in `src/http.bend`
# (`octs.len`, `octs.take`, `octs.drop`, and those built on them) count one
# octet per character, so every Content-Length and chunk size counts octets
# (RFC 9110 §8.6, RFC 9112 §6.3, §7.1). Text is decoded from octets only at
# the end, for the caller (`Qs.octets.text`, `step.text`), and a response
# body only when the caller asks (`body_text`). A text written onto the wire
# (a request's or a reply's text body) is still counted as its UTF-8 octets
# (`utf8.len`).
#
# For every received text `s` and count `n`, `octs.len(s)` is exactly
# `String.length(s)`, and `octs.take(s, n)` and `octs.drop(s, n)` are
# exactly `String.take(s, n)` and `String.drop(s, n)`: one octet per
# character.
import Base
import ../src/http.bend as Http

# --- bodies as octets ---

# LAW: a received text's octets are its characters, one each
law octs_len:
  for s: String
  {Http.octs.len(s) == String.length(s) : Nat}

# LAW: the first n octets of a received text are its first n characters
law octs_take:
  for s: String
  for +n: Nat
  {Http.octs.take(s, n) == String.take(s, n) : String}

# LAW: what follows the first n octets is what follows its first n
# characters
law octs_drop:
  for s: String
  for +n: Nat
  {Http.octs.drop(s, n) == String.drop(s, n) : String}

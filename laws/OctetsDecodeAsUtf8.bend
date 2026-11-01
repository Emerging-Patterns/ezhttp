# For every octet text `o`, its text (`Qs.octets.text`) is exactly `o`'s
# octets decoded as UTF-8 by `Qs.utf.dec`, one octet a byte
# (laws/Utf8DecodesWithReplacement.bend: an ill-formed sequence's maximal
# subpart is one U+FFFD), and so is each header name and value
# (`Qs.octets.headers`), in order; the client answers a response's header
# fields and reason phrase as text this way, and its body as the packed
# octets themselves (`bytes`), which `body_text` decodes this way only when
# it is called (trusted in src/client.bend and src/packed.bend).
import Base
import ../src/http.bend as Http
import ../src/qs.bend as Qs

# LAW: received octets as text are their UTF-8 decoding, one octet a byte
law octets_text:
  for o: String
  {Qs.octets.text(o) == Qs.utf.dec(Qs.octets.toks(o), Qs.Idle{}) : String}

# LAW: no octets are no pieces to decode
law octets_toks_nil:
  for s: String
  for e: {SNil{} == s : String}
  {Qs.octets.toks(s) == [] : List<&2, Qs.Tok>}

# LAW: each octet is one byte for the decoder, in order
law octets_toks_cons:
  for +c: Char
  for t: String
  {Qs.octets.toks(SCon{c, t}) == Qs.B{Char.to_u32(c)} <> Qs.octets.toks(t)
    : List<&2, Qs.Tok>}

# LAW: header fields as text are each name and value decoded, in order
law octets_headers_cons:
  for name: String
  for value: String
  for t: List<&2, Http.Header>
  {Qs.octets.headers(Http.H{name, value} <> t)
    == Http.H{Qs.octets.text(name), Qs.octets.text(value)}
      <> Qs.octets.headers(t) : List<&2, Http.Header>}

# LAW: no header fields are no header fields
law octets_headers_nil:
  for hs: List<&2, Http.Header>
  for e: {[] == hs : List<&2, Http.Header>}
  {Qs.octets.headers(hs) == [] : List<&2, Http.Header>}

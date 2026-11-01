# Bytes are decoded as UTF-8 one at a time (`Qs.utf.dec`). Between
# characters, a byte `00`-`7F` is that character; `C2`-`DF` opens a sequence
# needing one more byte, `E0` two (the next `A0`-`BF`), `E1`-`EC` and
# `EE`-`EF` two, `ED` two (the next `80`-`9F`), `F0` three (the next
# `90`-`BF`), `F1`-`F3` three, `F4` three (the next `80`-`8F`), each byte
# after the next `80`-`BF` (RFC 3629 §4's well-formed sequences, Unicode
# Table 3-7); `80`-`C1` and `F5`-`FF` are U+FFFD. A byte that fits the
# sequence adds its six low bits to the code point, and the last one ends it
# with that character. A byte that does not fit, a character outside ASCII,
# or the end of the bytes ends the sequence unfinished: what it has read is
# one U+FFFD (Unicode §3.9, substitution of maximal subparts, as Python's
# `errors="replace"` does), and the byte is read again between characters.
import Base
import ../src/qs.bend as Qs

# LAW: decoding ends where the pieces end
law qs_dec_nil:
  for st: Qs.Utf
  {Qs.utf.dec([], st) == Qs.utf.end(st) : String}

# LAW: pieces are decoded one at a time, from where the decoding stands
law qs_dec_cons:
  for t: Qs.Tok
  for rest: List<&2, Qs.Tok>
  for st: Qs.Utf
  {Qs.utf.dec(t <> rest, st)
    == Qs.utf.step(st, t, st2 => Qs.utf.dec(rest, st2)) : String}

# LAW: between characters, the end leaves nothing
law qs_end_idle:
  for st: Qs.Utf
  for e: {Qs.Idle{} == st : Qs.Utf}
  {Qs.utf.end(st) == "" : String}

# LAW (Unicode §3.9): a sequence the end leaves unfinished is one U+FFFD
law qs_end_need:
  for cp: U32
  for left: Nat
  for lo: U32
  for hi: U32
  {Qs.utf.end(Qs.Need{cp, left, lo, hi}) == SCon{Chr{65533}, ""} : String}

# LAW: between characters, a character outside ASCII is itself
law qs_idle_wide:
  for c: Char
  for k: Qs.Utf -> String
  {Qs.utf.step(Qs.Idle{}, Qs.W{c}, k) == SCon{c, k(Qs.Idle{})} : String}

# LAW: between characters, a byte is read by what it leads
law qs_idle_byte:
  for +b: U32
  for k: Qs.Utf -> String
  {Qs.utf.step(Qs.Idle{}, Qs.B{b}, k) == Qs.utf.lead(b, k, Qs.lead(b))
    : String}

# LAW: an ASCII byte is its character
law qs_lead_on_ascii:
  for +b: U32
  for k: Qs.Utf -> String
  {Qs.utf.lead(b, k, Qs.Ascii{}) == SCon{Chr{b}, k(Qs.Idle{})} : String}

# LAW (Unicode §3.9): a byte no sequence starts with is one U+FFFD
law qs_lead_on_bad:
  for +b: U32
  for k: Qs.Utf -> String
  {Qs.utf.lead(b, k, Qs.Bad{}) == SCon{Chr{65533}, k(Qs.Idle{})} : String}

# LAW: a lead byte opens its sequence
law qs_lead_on_opens:
  for +b: U32
  for k: Qs.Utf -> String
  for cp: U32
  for left: Nat
  for lo: U32
  for hi: U32
  {Qs.utf.lead(b, k, Qs.Opens{cp, left, lo, hi})
    == k(Qs.Need{cp, left, lo, hi}) : String}

# LAW (RFC 3629 §4): 00 to 7F is ASCII
law qs_lead_ascii:
  for +b: U32
  for e: {True{} == U32.is_lt(b, 128) : Bool}
  {Qs.lead(b) == Qs.Ascii{} : Qs.Lead}

# LAW (RFC 3629 §4): 80 to C1 start no sequence
law qs_lead_low:
  for +b: U32
  for e1: {False{} == U32.is_lt(b, 128) : Bool}
  for e2: {True{} == U32.is_lt(b, 194) : Bool}
  {Qs.lead(b) == Qs.Bad{} : Qs.Lead}

# LAW (RFC 3629 §4): C2 to DF need one byte 80 to BF
law qs_lead_two:
  for +b: U32
  for e1: {False{} == U32.is_lt(b, 128) : Bool}
  for e2: {False{} == U32.is_lt(b, 194) : Bool}
  for e3: {True{} == U32.is_lt(b, 224) : Bool}
  {Qs.lead(b) == Qs.Opens{U32.and(b, 31), 0n, 128, 191} : Qs.Lead}

# LAW (RFC 3629 §4): E0 needs A0 to BF, then one byte
law qs_lead_e0:
  for +b: U32
  for e1: {False{} == U32.is_lt(b, 128) : Bool}
  for e2: {False{} == U32.is_lt(b, 194) : Bool}
  for e3: {False{} == U32.is_lt(b, 224) : Bool}
  for e4: {True{} == U32.is_eq(b, 224) : Bool}
  {Qs.lead(b) == Qs.Opens{0, 1n, 160, 191} : Qs.Lead}

# LAW (RFC 3629 §4): E1 to EC need 80 to BF, then one byte
law qs_lead_e1:
  for +b: U32
  for e1: {False{} == U32.is_lt(b, 128) : Bool}
  for e2: {False{} == U32.is_lt(b, 194) : Bool}
  for e3: {False{} == U32.is_lt(b, 224) : Bool}
  for e4: {False{} == U32.is_eq(b, 224) : Bool}
  for e5: {True{} == U32.is_lt(b, 237) : Bool}
  {Qs.lead(b) == Qs.Opens{U32.and(b, 15), 1n, 128, 191} : Qs.Lead}

# LAW (RFC 3629 §4): ED needs 80 to 9F (no surrogates), then one byte
law qs_lead_ed:
  for +b: U32
  for e1: {False{} == U32.is_lt(b, 128) : Bool}
  for e2: {False{} == U32.is_lt(b, 194) : Bool}
  for e3: {False{} == U32.is_lt(b, 224) : Bool}
  for e4: {False{} == U32.is_eq(b, 224) : Bool}
  for e5: {False{} == U32.is_lt(b, 237) : Bool}
  for e6: {True{} == U32.is_eq(b, 237) : Bool}
  {Qs.lead(b) == Qs.Opens{13, 1n, 128, 159} : Qs.Lead}

# LAW (RFC 3629 §4): EE and EF need 80 to BF, then one byte
law qs_lead_ee:
  for +b: U32
  for e1: {False{} == U32.is_lt(b, 128) : Bool}
  for e2: {False{} == U32.is_lt(b, 194) : Bool}
  for e3: {False{} == U32.is_lt(b, 224) : Bool}
  for e4: {False{} == U32.is_eq(b, 224) : Bool}
  for e5: {False{} == U32.is_lt(b, 237) : Bool}
  for e6: {False{} == U32.is_eq(b, 237) : Bool}
  for e7: {True{} == U32.is_lt(b, 240) : Bool}
  {Qs.lead(b) == Qs.Opens{U32.and(b, 15), 1n, 128, 191} : Qs.Lead}

# LAW (RFC 3629 §4): F0 needs 90 to BF, then two bytes
law qs_lead_f0:
  for +b: U32
  for e1: {False{} == U32.is_lt(b, 128) : Bool}
  for e2: {False{} == U32.is_lt(b, 194) : Bool}
  for e3: {False{} == U32.is_lt(b, 224) : Bool}
  for e4: {False{} == U32.is_eq(b, 224) : Bool}
  for e5: {False{} == U32.is_lt(b, 237) : Bool}
  for e6: {False{} == U32.is_eq(b, 237) : Bool}
  for e7: {False{} == U32.is_lt(b, 240) : Bool}
  for e8: {True{} == U32.is_eq(b, 240) : Bool}
  {Qs.lead(b) == Qs.Opens{0, 2n, 144, 191} : Qs.Lead}

# LAW (RFC 3629 §4): F1 to F3 need 80 to BF, then two bytes
law qs_lead_f1:
  for +b: U32
  for e1: {False{} == U32.is_lt(b, 128) : Bool}
  for e2: {False{} == U32.is_lt(b, 194) : Bool}
  for e3: {False{} == U32.is_lt(b, 224) : Bool}
  for e4: {False{} == U32.is_eq(b, 224) : Bool}
  for e5: {False{} == U32.is_lt(b, 237) : Bool}
  for e6: {False{} == U32.is_eq(b, 237) : Bool}
  for e7: {False{} == U32.is_lt(b, 240) : Bool}
  for e8: {False{} == U32.is_eq(b, 240) : Bool}
  for e9: {True{} == U32.is_lt(b, 244) : Bool}
  {Qs.lead(b) == Qs.Opens{U32.and(b, 7), 2n, 128, 191} : Qs.Lead}

# LAW (RFC 3629 §4): F4 needs 80 to 8F (up to U+10FFFF), then two bytes
law qs_lead_f4:
  for +b: U32
  for e1: {False{} == U32.is_lt(b, 128) : Bool}
  for e2: {False{} == U32.is_lt(b, 194) : Bool}
  for e3: {False{} == U32.is_lt(b, 224) : Bool}
  for e4: {False{} == U32.is_eq(b, 224) : Bool}
  for e5: {False{} == U32.is_lt(b, 237) : Bool}
  for e6: {False{} == U32.is_eq(b, 237) : Bool}
  for e7: {False{} == U32.is_lt(b, 240) : Bool}
  for e8: {False{} == U32.is_eq(b, 240) : Bool}
  for e9: {False{} == U32.is_lt(b, 244) : Bool}
  for e10: {True{} == U32.is_eq(b, 244) : Bool}
  {Qs.lead(b) == Qs.Opens{4, 2n, 128, 143} : Qs.Lead}

# LAW (RFC 3629 §4): F5 and up start no sequence
law qs_lead_high:
  for +b: U32
  for e1: {False{} == U32.is_lt(b, 128) : Bool}
  for e2: {False{} == U32.is_lt(b, 194) : Bool}
  for e3: {False{} == U32.is_lt(b, 224) : Bool}
  for e4: {False{} == U32.is_eq(b, 224) : Bool}
  for e5: {False{} == U32.is_lt(b, 237) : Bool}
  for e6: {False{} == U32.is_eq(b, 237) : Bool}
  for e7: {False{} == U32.is_lt(b, 240) : Bool}
  for e8: {False{} == U32.is_eq(b, 240) : Bool}
  for e9: {False{} == U32.is_lt(b, 244) : Bool}
  for e10: {False{} == U32.is_eq(b, 244) : Bool}
  {Qs.lead(b) == Qs.Bad{} : Qs.Lead}

# LAW (Unicode §3.9): a character outside ASCII inside a sequence ends it
# unfinished, one U+FFFD, and is itself
law qs_need_wide:
  for cp: U32
  for left: Nat
  for lo: U32
  for hi: U32
  for c: Char
  for k: Qs.Utf -> String
  {Qs.utf.step(Qs.Need{cp, left, lo, hi}, Qs.W{c}, k)
    == SCon{Chr{65533}, SCon{c, k(Qs.Idle{})}} : String}

# LAW (RFC 3629 §3): the last byte that fits ends the character
law qs_need_last:
  for +cp: U32
  for +lo: U32
  for +hi: U32
  for +b: U32
  for k: Qs.Utf -> String
  for e: {True{} == Bool.and(U32.is_le(lo, b), U32.is_le(b, hi)) : Bool}
  {Qs.utf.step(Qs.Need{cp, 0n, lo, hi}, Qs.B{b}, k)
    == SCon{Chr{Qs.utf.add(cp, b)}, k(Qs.Idle{})} : String}

# LAW (RFC 3629 §3): a byte that fits with more to come adds its bits and
# needs the next in 80 to BF
law qs_need_more:
  for +cp: U32
  for l: Nat
  for +lo: U32
  for +hi: U32
  for +b: U32
  for k: Qs.Utf -> String
  for e: {True{} == Bool.and(U32.is_le(lo, b), U32.is_le(b, hi)) : Bool}
  {Qs.utf.step(Qs.Need{cp, 1n+l, lo, hi}, Qs.B{b}, k)
    == k(Qs.Need{Qs.utf.add(cp, b), l, 128, 191}) : String}

# LAW (Unicode §3.9): a byte that does not fit ends the sequence unfinished,
# one U+FFFD, and is read again between characters
law qs_need_miss:
  for +cp: U32
  for left: Nat
  for +lo: U32
  for +hi: U32
  for +b: U32
  for k: Qs.Utf -> String
  for e: {False{} == Bool.and(U32.is_le(lo, b), U32.is_le(b, hi)) : Bool}
  {Qs.utf.step(Qs.Need{cp, left, lo, hi}, Qs.B{b}, k)
    == SCon{Chr{65533}, Qs.utf.lead(b, k, Qs.lead(b))} : String}

# LAW (RFC 3629 §3): a continuation byte adds its six low bits
law qs_add:
  for +cp: U32
  for +b: U32
  {Qs.utf.add(cp, b) == U32.or(U32.shln(cp, 6n), U32.and(b, 63)) : U32}

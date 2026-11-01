# `unquote_plus` is `unquote` with every `+` outside an escape read as the
# byte of a space (WHATWG URL §5.1 step 3.3: "replace any 0x2B (+) in name
# and value with 0x20 (SP)"), as Python replaces `+` before it unquotes;
# `%2B` stays `+`.
#
# also rests on: laws/UnquoteReadsEscapes.bend
import Base
import ../src/qs.bend as Qs

# LAW: unquote_plus is the same reading with `+` as a space
law qs_unquote_plus:
  for s: String
  {Qs.unquote.plus(s)
    == Qs.utf.dec(Qs.toks(s, True{}, Qs.Plain{}), Qs.Idle{}) : String}

# LAW (WHATWG URL §5.1 step 3.3): with `plus`, `+` is the byte of a space
law qs_byte_plus:
  for +c: Char
  for e: {True{} == Char.is_eq(c, '+') : Bool}
  {Qs.tok.byte(True{}, c) == 32 : U32}

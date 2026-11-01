# proofs of laws/UnquoteReadsEscapes.bend
import Base
import ../src/http.bend as Http
import ../src/qs.bend as Qs
import ../laws/UnquoteReadsEscapes.bend as Laws

# --- percent-decoding and query strings ---

def Laws.qs_unquote(_s):
  {==}

def Laws.qs_toks_nil(_plus, _st):
  {==}

def Laws.qs_toks_cons(_c, _t, _plus, _st):
  {==}

def Laws.qs_tok_wide(plus, c, k, e):
  %e : {Qs.tok.wide(plus, c, k, _) == Qs.W{c} <> k(Qs.Plain{})
    : List<&2, Qs.Tok>}
  {==}

def Laws.qs_tok_open(plus, c, k, e1, e2):
  %e1 : {Qs.tok.wide(plus, c, k, _) == k(Qs.Pct{}) : List<&2, Qs.Tok>}
  %e2 : {Qs.tok.ascii(plus, c, k, _) == k(Qs.Pct{}) : List<&2, Qs.Tok>}
  {==}

def Laws.qs_tok_byte(plus, c, k, e1, e2):
  %e1 : {Qs.tok.wide(plus, c, k, _)
    == Qs.B{Qs.tok.byte(plus, c)} <> k(Qs.Plain{}) : List<&2, Qs.Tok>}
  %e2 : {Qs.tok.ascii(plus, c, k, _)
    == Qs.B{Qs.tok.byte(plus, c)} <> k(Qs.Plain{}) : List<&2, Qs.Tok>}
  {==}

def Laws.qs_byte_other(_plus, c, e):
  %e : {Bool.pick(U32, _, 32, Char.to_u32(c)) == Char.to_u32(c) : U32}
  {==}

def Laws.qs_tok_pct_hex(plus, c, k, e):
  %e : {Qs.tok.pct(plus, c, k, _) == k(Qs.Pct1{c}) : List<&2, Qs.Tok>}
  {==}

def Laws.qs_tok_pct_other(plus, c, k, e):
  %e : {Qs.tok.pct(plus, c, k, _)
    == Qs.B{37} <> Qs.tok.step(plus, Qs.Plain{}, c, k) : List<&2, Qs.Tok>}
  {==}

def Laws.qs_tok_pct1_hex(plus, d, c, k, e):
  %e : {Qs.tok.pct1(plus, d, c, k, _)
    == Qs.B{U32.add(U32.mul(Http.hex.val(d), 16), Http.hex.val(c))}
      <> k(Qs.Plain{}) : List<&2, Qs.Tok>}
  {==}

def Laws.qs_tok_pct1_other(plus, d, c, k, e):
  %e : {Qs.tok.pct1(plus, d, c, k, _)
    == Qs.B{37} <> (Qs.B{Char.to_u32(d)}
      <> Qs.tok.step(plus, Qs.Plain{}, c, k)) : List<&2, Qs.Tok>}
  {==}

def Laws.qs_tok_end_plain(_st, e):
  %e : {Qs.tok.end(_) == [] : List<&2, Qs.Tok>}
  {==}

def Laws.qs_tok_end_pct(_st, e):
  %e : {Qs.tok.end(_) == [Qs.B{37}] : List<&2, Qs.Tok>}
  {==}

def Laws.qs_tok_end_pct1(_d):
  {==}

def Laws.qs_tok_hex(_c):
  {==}

def Laws.qs_hexval_dec(u, e):
  %e : {Bool.pick(U32, _, U32.sub(u, 48),
    Bool.pick(U32, Bool.and(U32.is_ge(u, 97), U32.is_le(u, 102)),
      U32.sub(u, 87),
      Bool.pick(U32, Bool.and(U32.is_ge(u, 65), U32.is_le(u, 70)),
        U32.sub(u, 55), 16))) == U32.sub(u, 48) : U32}
  {==}

def Laws.qs_hexval_upper(u, e1, e2, e3):
  %e1 : {Bool.pick(U32, _, U32.sub(u, 48),
    Bool.pick(U32, Bool.and(U32.is_ge(u, 97), U32.is_le(u, 102)),
      U32.sub(u, 87),
      Bool.pick(U32, Bool.and(U32.is_ge(u, 65), U32.is_le(u, 70)),
        U32.sub(u, 55), 16))) == U32.sub(u, 55) : U32}
  %e2 : {Bool.pick(U32, _, U32.sub(u, 87),
    Bool.pick(U32, Bool.and(U32.is_ge(u, 65), U32.is_le(u, 70)),
      U32.sub(u, 55), 16)) == U32.sub(u, 55) : U32}
  %e3 : {Bool.pick(U32, _, U32.sub(u, 55), 16) == U32.sub(u, 55) : U32}
  {==}

def Laws.qs_hexval_lower(u, e1, e2):
  %e1 : {Bool.pick(U32, _, U32.sub(u, 48),
    Bool.pick(U32, Bool.and(U32.is_ge(u, 97), U32.is_le(u, 102)),
      U32.sub(u, 87),
      Bool.pick(U32, Bool.and(U32.is_ge(u, 65), U32.is_le(u, 70)),
        U32.sub(u, 55), 16))) == U32.sub(u, 87) : U32}
  %e2 : {Bool.pick(U32, _, U32.sub(u, 87),
    Bool.pick(U32, Bool.and(U32.is_ge(u, 65), U32.is_le(u, 70)),
      U32.sub(u, 55), 16)) == U32.sub(u, 87) : U32}
  {==}

def Laws.qs_hexval_none(u, e1, e2, e3):
  %e1 : {Bool.pick(U32, _, U32.sub(u, 48),
    Bool.pick(U32, Bool.and(U32.is_ge(u, 97), U32.is_le(u, 102)),
      U32.sub(u, 87),
      Bool.pick(U32, Bool.and(U32.is_ge(u, 65), U32.is_le(u, 70)),
        U32.sub(u, 55), 16))) == 16 : U32}
  %e2 : {Bool.pick(U32, _, U32.sub(u, 87),
    Bool.pick(U32, Bool.and(U32.is_ge(u, 65), U32.is_le(u, 70)),
      U32.sub(u, 55), 16)) == 16 : U32}
  %e3 : {Bool.pick(U32, _, U32.sub(u, 55), 16) == 16 : U32}
  {==}

# proofs of laws/UnescapeFindsReferences.bend
import Base
import ../src/unescape.bend as Ref
import ../laws/UnescapeFindsReferences.bend as Laws

# --- HTML character references ---

def Laws.ref_unescape(_s):
  {==}

def Laws.ref_scan_nil(_st):
  {==}

def Laws.ref_scan_cons(_c, _t, _st):
  {==}

def Laws.ref_text_amp(c, k, e):
  %e : {Ref.text.of(c, k, _) == k(Ref.Amp{}) : String}
  {==}

def Laws.ref_text_other(c, k, e):
  %e : {Ref.text.of(c, k, _) == SCon{c, k(Ref.Txt{})} : String}
  {==}

def Laws.ref_amp_hash(c, k, e):
  %e : {Ref.amp(c, k, _) == k(Ref.Hash{}) : String}
  {==}

def Laws.ref_amp_name(c, k, e1, e2):
  %e1 : {Ref.amp(c, k, _) == k(Ref.Name{SCon{c, ""}, 1n}) : String}
  %e2 : {Ref.amp.name(c, k, _) == k(Ref.Name{SCon{c, ""}, 1n}) : String}
  {==}

def Laws.ref_amp_other(c, k, e1, e2):
  %e1 : {Ref.amp(c, k, _) == SCon{'&', Ref.step(Ref.Txt{}, c, k)} : String}
  %e2 : {Ref.amp.name(c, k, _) == SCon{'&', Ref.step(Ref.Txt{}, c, k)}
    : String}
  {==}

def Laws.ref_hash_dec(c, k, e):
  %e : {Ref.hash.dec(c, k, Ref.digit(False{}, c), _)
    == k(Ref.Num{False{}, Ref.digit(False{}, c)}) : String}
  {==}

def Laws.ref_hash_x(c, k, e1, e2):
  %e1 : {Ref.hash.dec(c, k, Ref.digit(False{}, c), _) == k(Ref.HashX{c})
    : String}
  %e2 : {Ref.hash.x(c, k, _) == k(Ref.HashX{c}) : String}
  {==}

def Laws.ref_hash_other(c, k, e1, e2):
  %e1 : {Ref.hash.dec(c, k, Ref.digit(False{}, c), _)
    == "&#" ++ Ref.step(Ref.Txt{}, c, k) : String}
  %e2 : {Ref.hash.x(c, k, _) == "&#" ++ Ref.step(Ref.Txt{}, c, k) : String}
  {==}

def Laws.ref_hashx_digit(x, c, k, e):
  %e : {Ref.hash.hex.of(x, c, k, Ref.digit(True{}, c), _)
    == k(Ref.Num{True{}, Ref.digit(True{}, c)}) : String}
  {==}

def Laws.ref_hashx_other(x, c, k, e):
  %e : {Ref.hash.hex.of(x, c, k, Ref.digit(True{}, c), _)
    == SCon{'&', SCon{'#', SCon{x, Ref.step(Ref.Txt{}, c, k)}}} : String}
  {==}

def Laws.ref_num_digit(hex, n, c, k, e):
  %e : {Ref.num(hex, n, c, k, Ref.digit(hex, c), _)
    == k(Ref.Num{hex, Ref.grow(hex, n, Ref.digit(hex, c))}) : String}
  {==}

def Laws.ref_num_semi(hex, n, c, k, e1, e2):
  %e1 : {Ref.num(hex, n, c, k, Ref.digit(hex, c), _)
    == Ref.code(n) ++ k(Ref.Txt{}) : String}
  %e2 : {Ref.num.end(n, c, k, _) == Ref.code(n) ++ k(Ref.Txt{}) : String}
  {==}

def Laws.ref_num_other(hex, n, c, k, e1, e2):
  %e1 : {Ref.num(hex, n, c, k, Ref.digit(hex, c), _)
    == Ref.code(n) ++ Ref.step(Ref.Txt{}, c, k) : String}
  %e2 : {Ref.num.end(n, c, k, _) == Ref.code(n) ++ Ref.step(Ref.Txt{}, c, k)
    : String}
  {==}

def Laws.ref_name_semi(s, len, c, k, e):
  %e : {Ref.name(s, len, c, k, _) == Ref.named(s ++ ";") ++ k(Ref.Txt{})
    : String}
  {==}

def Laws.ref_name_join(s, len, c, k, e1, e2):
  %e1 : {Ref.name(s, len, c, k, _)
    == k(Ref.Name{s ++ SCon{c, ""}, 1n+len}) : String}
  %e2 : {Ref.name.more(s, len, c, k, _)
    == k(Ref.Name{s ++ SCon{c, ""}, 1n+len}) : String}
  {==}

def Laws.ref_name_stop(s, len, c, k, e1, e2):
  %e1 : {Ref.name(s, len, c, k, _)
    == Ref.named(s) ++ Ref.step(Ref.Txt{}, c, k) : String}
  %e2 : {Ref.name.more(s, len, c, k, _)
    == Ref.named(s) ++ Ref.step(Ref.Txt{}, c, k) : String}
  {==}

def Laws.ref_end_text(_st, e):
  %e : {Ref.end(_) == "" : String}
  {==}

def Laws.ref_end_amp(_st, e):
  %e : {Ref.end(_) == "&" : String}
  {==}

def Laws.ref_end_hash(_st, e):
  %e : {Ref.end(_) == "&#" : String}
  {==}

def Laws.ref_end_hashx(_x):
  {==}

def Laws.ref_end_num(_hex, _n):
  {==}

def Laws.ref_end_name(_s, _len):
  {==}

def Laws.ref_name_char(_c):
  {==}

def Laws.ref_digit_dec(u, e):
  %e : {Bool.pick(U32, _, U32.sub(u, 48), 16) == U32.sub(u, 48) : U32}
  {==}

def Laws.ref_digit_dec_none(u, e):
  %e : {Bool.pick(U32, _, U32.sub(u, 48), 16) == 16 : U32}
  {==}

def Laws.ref_digit_hex_dec(u, e):
  %e : {Bool.pick(U32, _, U32.sub(u, 48),
    Bool.pick(U32, Bool.and(U32.is_le(65, u), U32.is_le(u, 70)),
      U32.sub(u, 55),
      Bool.pick(U32, Bool.and(U32.is_le(97, u), U32.is_le(u, 102)),
        U32.sub(u, 87), 16))) == U32.sub(u, 48) : U32}
  {==}

def Laws.ref_digit_hex_upper(u, e1, e2):
  %e1 : {Bool.pick(U32, _, U32.sub(u, 48),
    Bool.pick(U32, Bool.and(U32.is_le(65, u), U32.is_le(u, 70)),
      U32.sub(u, 55),
      Bool.pick(U32, Bool.and(U32.is_le(97, u), U32.is_le(u, 102)),
        U32.sub(u, 87), 16))) == U32.sub(u, 55) : U32}
  %e2 : {Bool.pick(U32, _, U32.sub(u, 55),
    Bool.pick(U32, Bool.and(U32.is_le(97, u), U32.is_le(u, 102)),
      U32.sub(u, 87), 16)) == U32.sub(u, 55) : U32}
  {==}

def Laws.ref_digit_hex_lower(u, e1, e2, e3):
  %e1 : {Bool.pick(U32, _, U32.sub(u, 48),
    Bool.pick(U32, Bool.and(U32.is_le(65, u), U32.is_le(u, 70)),
      U32.sub(u, 55),
      Bool.pick(U32, Bool.and(U32.is_le(97, u), U32.is_le(u, 102)),
        U32.sub(u, 87), 16))) == U32.sub(u, 87) : U32}
  %e2 : {Bool.pick(U32, _, U32.sub(u, 55),
    Bool.pick(U32, Bool.and(U32.is_le(97, u), U32.is_le(u, 102)),
      U32.sub(u, 87), 16)) == U32.sub(u, 87) : U32}
  %e3 : {Bool.pick(U32, _, U32.sub(u, 87), 16) == U32.sub(u, 87) : U32}
  {==}

def Laws.ref_digit_hex_none(u, e1, e2, e3):
  %e1 : {Bool.pick(U32, _, U32.sub(u, 48),
    Bool.pick(U32, Bool.and(U32.is_le(65, u), U32.is_le(u, 70)),
      U32.sub(u, 55),
      Bool.pick(U32, Bool.and(U32.is_le(97, u), U32.is_le(u, 102)),
        U32.sub(u, 87), 16))) == 16 : U32}
  %e2 : {Bool.pick(U32, _, U32.sub(u, 55),
    Bool.pick(U32, Bool.and(U32.is_le(97, u), U32.is_le(u, 102)),
      U32.sub(u, 87), 16)) == 16 : U32}
  %e3 : {Bool.pick(U32, _, U32.sub(u, 87), 16) == 16 : U32}
  {==}

def Laws.ref_grow(_hex, _n, _d):
  {==}

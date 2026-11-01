# proofs of laws/QuoteEscapesUtf8Bytes.bend
import Base
import ../src/pct.bend as Pct
import ../laws/QuoteEscapesUtf8Bytes.bend as Laws

def Laws.one_escaped(_slash, c, e, rest):
  %e : {Pct.one.of(c, rest, _) == Pct.pct(Pct.utf8(c), rest) : String}
  {==}

def Laws.pct_nil(_rest):
  {==}

def Laws.pct_cons(_b, _bs, _rest):
  {==}

def Laws.hex_digit(n, e):
  %e : {Chr{Bool.pick(U32, _, U32.add(48, n), U32.add(55, n))}
    == Chr{U32.add(48, n)} : Char}
  {==}

def Laws.hex_letter(n, e):
  %e : {Chr{Bool.pick(U32, _, U32.add(48, n), U32.add(55, n))}
    == Chr{U32.add(55, n)} : Char}
  {==}

def Laws.utf8_one(c, e):
  %e : {Pct.utf8.one(c, _) == [c] : List<&2, U32>}
  {==}

def Laws.utf8_two(c, e1, e2):
  %e1 : {Pct.utf8.one(c, _) == [U32.or(192, U32.shrn(c, 6n)),
    U32.or(128, U32.and(c, 63))] : List<&2, U32>}
  %e2 : {Pct.utf8.two(c, _) == [U32.or(192, U32.shrn(c, 6n)),
    U32.or(128, U32.and(c, 63))] : List<&2, U32>}
  {==}

def Laws.utf8_three(c, e1, e2, e3):
  %e1 : {Pct.utf8.one(c, _) == [U32.or(224, U32.shrn(c, 12n)),
    U32.or(128, U32.and(U32.shrn(c, 6n), 63)),
    U32.or(128, U32.and(c, 63))] : List<&2, U32>}
  %e2 : {Pct.utf8.two(c, _) == [U32.or(224, U32.shrn(c, 12n)),
    U32.or(128, U32.and(U32.shrn(c, 6n), 63)),
    U32.or(128, U32.and(c, 63))] : List<&2, U32>}
  %e3 : {Pct.utf8.three(c, _) == [U32.or(224, U32.shrn(c, 12n)),
    U32.or(128, U32.and(U32.shrn(c, 6n), 63)),
    U32.or(128, U32.and(c, 63))] : List<&2, U32>}
  {==}

def Laws.utf8_four(c, e1, e2, e3):
  %e1 : {Pct.utf8.one(c, _) == [U32.or(240, U32.shrn(c, 18n)),
    U32.or(128, U32.and(U32.shrn(c, 12n), 63)),
    U32.or(128, U32.and(U32.shrn(c, 6n), 63)),
    U32.or(128, U32.and(c, 63))] : List<&2, U32>}
  %e2 : {Pct.utf8.two(c, _) == [U32.or(240, U32.shrn(c, 18n)),
    U32.or(128, U32.and(U32.shrn(c, 12n), 63)),
    U32.or(128, U32.and(U32.shrn(c, 6n), 63)),
    U32.or(128, U32.and(c, 63))] : List<&2, U32>}
  %e3 : {Pct.utf8.three(c, _) == [U32.or(240, U32.shrn(c, 18n)),
    U32.or(128, U32.and(U32.shrn(c, 12n), 63)),
    U32.or(128, U32.and(U32.shrn(c, 6n), 63)),
    U32.or(128, U32.and(c, 63))] : List<&2, U32>}
  {==}

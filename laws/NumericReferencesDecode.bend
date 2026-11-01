# A numeric reference's number `n` stands for (§13.2.5.80, Python's
# `_replace_charref`): U+FFFD for 0; U+000D for 0x0D; for 0x80 to 0x9F the
# character the §13.2.5.80 table names (Windows-1252: 0x80 U+20AC, 0x82
# U+201A, 0x83 U+0192, 0x84 U+201E, 0x85 U+2026, 0x86 U+2020, 0x87 U+2021,
# 0x88 U+02C6, 0x89 U+2030, 0x8A U+0160, 0x8B U+2039, 0x8C U+0152, 0x8E
# U+017D, 0x91 U+2018, 0x92 U+2019, 0x93 U+201C, 0x94 U+201D, 0x95 U+2022,
# 0x96 U+2013, 0x97 U+2014, 0x98 U+02DC, 0x99 U+2122, 0x9A U+0161, 0x9B
# U+203A, 0x9C U+0153, 0x9E U+017E, 0x9F U+0178; 0x81, 0x8D, 0x8F, 0x90 and
# 0x9D themselves); U+FFFD for a surrogate (0xD800 to 0xDFFF) or a number
# past 0x10FFFF; nothing (Python drops what the standard calls a control or
# noncharacter reference error) for 0x01 to 0x08, 0x0B, 0x0E to 0x1F, 0x7F
# to 0x9F, 0xFDD0 to 0xFDEF and every number whose low 16 bits are 0xFFFE or
# 0xFFFF; and the character `n` for every other number.
import Base
import ../src/unescape.bend as Ref

# LAW (§13.2.5.80): a number is read from 0 on
law ref_code:
  for +n: U32
  {Ref.code(n) == Ref.code.zero(n, U32.is_eq(n, 0)) : String}

# LAW (§13.2.5.80): 0 is U+FFFD
law ref_code_zero:
  for +n: U32
  for e: {True{} == U32.is_eq(n, 0) : Bool}
  {Ref.code(n) == SCon{Chr{65533}, ""} : String}

# LAW (§13.2.5.80): 0x0D is a carriage return
law ref_code_cr:
  for +n: U32
  for e1: {False{} == U32.is_eq(n, 0) : Bool}
  for e2: {True{} == U32.is_eq(n, 13) : Bool}
  {Ref.code(n) == "\r" : String}

# LAW (§13.2.5.80): 0x80 to 0x9F are the table's
law ref_code_c1:
  for +n: U32
  for e1: {False{} == U32.is_eq(n, 0) : Bool}
  for e2: {False{} == U32.is_eq(n, 13) : Bool}
  for e3: {True{} == Bool.and(U32.is_le(128, n), U32.is_le(n, 159)) : Bool}
  {Ref.code(n)
    == SCon{Chr{Ref.nth(Ref.w1252(), U32.to_nat(U32.sub(n, 128)))}, ""}
    : String}

# LAW (§13.2.5.80): a surrogate or a number past U+10FFFF is U+FFFD
law ref_code_bad:
  for +n: U32
  for e1: {False{} == U32.is_eq(n, 0) : Bool}
  for e2: {False{} == U32.is_eq(n, 13) : Bool}
  for e3: {False{} == Bool.and(U32.is_le(128, n), U32.is_le(n, 159)) : Bool}
  for e4: {True{} == Bool.or(Bool.and(U32.is_le(55296, n),
    U32.is_le(n, 57343)), U32.is_lt(1114111, n)) : Bool}
  {Ref.code(n) == SCon{Chr{65533}, ""} : String}

# LAW: a control or noncharacter Python drops is nothing
law ref_code_dropped:
  for +n: U32
  for e1: {False{} == U32.is_eq(n, 0) : Bool}
  for e2: {False{} == U32.is_eq(n, 13) : Bool}
  for e3: {False{} == Bool.and(U32.is_le(128, n), U32.is_le(n, 159)) : Bool}
  for e4: {False{} == Bool.or(Bool.and(U32.is_le(55296, n),
    U32.is_le(n, 57343)), U32.is_lt(1114111, n)) : Bool}
  for e5: {True{} == Ref.dropped(n) : Bool}
  {Ref.code(n) == "" : String}

# LAW: every other number is its character
law ref_code_kept:
  for +n: U32
  for e1: {False{} == U32.is_eq(n, 0) : Bool}
  for e2: {False{} == U32.is_eq(n, 13) : Bool}
  for e3: {False{} == Bool.and(U32.is_le(128, n), U32.is_le(n, 159)) : Bool}
  for e4: {False{} == Bool.or(Bool.and(U32.is_le(55296, n),
    U32.is_le(n, 57343)), U32.is_lt(1114111, n)) : Bool}
  for e5: {False{} == Ref.dropped(n) : Bool}
  {Ref.code(n) == SCon{Chr{n}, ""} : String}

# LAW: what Python drops: 0x01 to 0x08, 0x0B, 0x0E to 0x1F, 0x7F to 0x9F,
# 0xFDD0 to 0xFDEF, and low 16 bits 0xFFFE or 0xFFFF
law ref_dropped:
  for +n: U32
  {Ref.dropped(n) == Bool.or(Bool.and(U32.is_le(1, n), U32.is_le(n, 8)),
    Bool.or(U32.is_eq(n, 11),
      Bool.or(Bool.and(U32.is_le(14, n), U32.is_le(n, 31)),
        Bool.or(Bool.and(U32.is_le(127, n), U32.is_le(n, 159)),
          Bool.or(Bool.and(U32.is_le(64976, n), U32.is_le(n, 65007)),
            U32.is_eq(U32.and(n, 65534), 65534)))))) : Bool}

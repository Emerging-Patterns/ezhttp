# proofs of laws/Utf8DecodesWithReplacement.bend
import Base
import ../src/qs.bend as Qs
import ../laws/Utf8DecodesWithReplacement.bend as Laws

def Laws.qs_dec_nil(_st):
  {==}

def Laws.qs_dec_cons(_t, _rest, _st):
  {==}

def Laws.qs_end_idle(_st, e):
  %e : {Qs.utf.end(_) == "" : String}
  {==}

def Laws.qs_end_need(_cp, _left, _lo, _hi):
  {==}

def Laws.qs_idle_wide(_c, _k):
  {==}

def Laws.qs_idle_byte(_b, _k):
  {==}

def Laws.qs_lead_on_ascii(_b, _k):
  {==}

def Laws.qs_lead_on_bad(_b, _k):
  {==}

def Laws.qs_lead_on_opens(_b, _k, _cp, _left, _lo, _hi):
  {==}

def Laws.qs_lead_ascii(b, e):
  %e : {Qs.lead.ascii(b, _) == Qs.Ascii{} : Qs.Lead}
  {==}

def Laws.qs_lead_low(b, e1, e2):
  %e1 : {Qs.lead.ascii(b, _) == Qs.Bad{} : Qs.Lead}
  %e2 : {Qs.lead.low(b, _) == Qs.Bad{} : Qs.Lead}
  {==}

def Laws.qs_lead_two(b, e1, e2, e3):
  %e1 : {Qs.lead.ascii(b, _) == Qs.Opens{U32.and(b, 31), 0n, 128, 191}
    : Qs.Lead}
  %e2 : {Qs.lead.low(b, _) == Qs.Opens{U32.and(b, 31), 0n, 128, 191}
    : Qs.Lead}
  %e3 : {Qs.lead.two(b, _) == Qs.Opens{U32.and(b, 31), 0n, 128, 191}
    : Qs.Lead}
  {==}

def Laws.qs_lead_e0(b, e1, e2, e3, e4):
  %e1 : {Qs.lead.ascii(b, _) == Qs.Opens{0, 1n, 160, 191} : Qs.Lead}
  %e2 : {Qs.lead.low(b, _) == Qs.Opens{0, 1n, 160, 191} : Qs.Lead}
  %e3 : {Qs.lead.two(b, _) == Qs.Opens{0, 1n, 160, 191} : Qs.Lead}
  %e4 : {Qs.lead.e0(b, _) == Qs.Opens{0, 1n, 160, 191} : Qs.Lead}
  {==}

def Laws.qs_lead_e1(b, e1, e2, e3, e4, e5):
  %e1 : {Qs.lead.ascii(b, _) == Qs.Opens{U32.and(b, 15), 1n, 128, 191}
    : Qs.Lead}
  %e2 : {Qs.lead.low(b, _) == Qs.Opens{U32.and(b, 15), 1n, 128, 191}
    : Qs.Lead}
  %e3 : {Qs.lead.two(b, _) == Qs.Opens{U32.and(b, 15), 1n, 128, 191}
    : Qs.Lead}
  %e4 : {Qs.lead.e0(b, _) == Qs.Opens{U32.and(b, 15), 1n, 128, 191}
    : Qs.Lead}
  %e5 : {Qs.lead.e1(b, _) == Qs.Opens{U32.and(b, 15), 1n, 128, 191}
    : Qs.Lead}
  {==}

def Laws.qs_lead_ed(b, e1, e2, e3, e4, e5, e6):
  %e1 : {Qs.lead.ascii(b, _) == Qs.Opens{13, 1n, 128, 159} : Qs.Lead}
  %e2 : {Qs.lead.low(b, _) == Qs.Opens{13, 1n, 128, 159} : Qs.Lead}
  %e3 : {Qs.lead.two(b, _) == Qs.Opens{13, 1n, 128, 159} : Qs.Lead}
  %e4 : {Qs.lead.e0(b, _) == Qs.Opens{13, 1n, 128, 159} : Qs.Lead}
  %e5 : {Qs.lead.e1(b, _) == Qs.Opens{13, 1n, 128, 159} : Qs.Lead}
  %e6 : {Qs.lead.ed(b, _) == Qs.Opens{13, 1n, 128, 159} : Qs.Lead}
  {==}

def Laws.qs_lead_ee(b, e1, e2, e3, e4, e5, e6, e7):
  %e1 : {Qs.lead.ascii(b, _) == Qs.Opens{U32.and(b, 15), 1n, 128, 191}
    : Qs.Lead}
  %e2 : {Qs.lead.low(b, _) == Qs.Opens{U32.and(b, 15), 1n, 128, 191}
    : Qs.Lead}
  %e3 : {Qs.lead.two(b, _) == Qs.Opens{U32.and(b, 15), 1n, 128, 191}
    : Qs.Lead}
  %e4 : {Qs.lead.e0(b, _) == Qs.Opens{U32.and(b, 15), 1n, 128, 191}
    : Qs.Lead}
  %e5 : {Qs.lead.e1(b, _) == Qs.Opens{U32.and(b, 15), 1n, 128, 191}
    : Qs.Lead}
  %e6 : {Qs.lead.ed(b, _) == Qs.Opens{U32.and(b, 15), 1n, 128, 191}
    : Qs.Lead}
  %e7 : {Qs.lead.ee(b, _) == Qs.Opens{U32.and(b, 15), 1n, 128, 191}
    : Qs.Lead}
  {==}

def Laws.qs_lead_f0(b, e1, e2, e3, e4, e5, e6, e7, e8):
  %e1 : {Qs.lead.ascii(b, _) == Qs.Opens{0, 2n, 144, 191} : Qs.Lead}
  %e2 : {Qs.lead.low(b, _) == Qs.Opens{0, 2n, 144, 191} : Qs.Lead}
  %e3 : {Qs.lead.two(b, _) == Qs.Opens{0, 2n, 144, 191} : Qs.Lead}
  %e4 : {Qs.lead.e0(b, _) == Qs.Opens{0, 2n, 144, 191} : Qs.Lead}
  %e5 : {Qs.lead.e1(b, _) == Qs.Opens{0, 2n, 144, 191} : Qs.Lead}
  %e6 : {Qs.lead.ed(b, _) == Qs.Opens{0, 2n, 144, 191} : Qs.Lead}
  %e7 : {Qs.lead.ee(b, _) == Qs.Opens{0, 2n, 144, 191} : Qs.Lead}
  %e8 : {Qs.lead.f0(b, _) == Qs.Opens{0, 2n, 144, 191} : Qs.Lead}
  {==}

def Laws.qs_lead_f1(b, e1, e2, e3, e4, e5, e6, e7, e8, e9):
  %e1 : {Qs.lead.ascii(b, _) == Qs.Opens{U32.and(b, 7), 2n, 128, 191}
    : Qs.Lead}
  %e2 : {Qs.lead.low(b, _) == Qs.Opens{U32.and(b, 7), 2n, 128, 191}
    : Qs.Lead}
  %e3 : {Qs.lead.two(b, _) == Qs.Opens{U32.and(b, 7), 2n, 128, 191}
    : Qs.Lead}
  %e4 : {Qs.lead.e0(b, _) == Qs.Opens{U32.and(b, 7), 2n, 128, 191}
    : Qs.Lead}
  %e5 : {Qs.lead.e1(b, _) == Qs.Opens{U32.and(b, 7), 2n, 128, 191}
    : Qs.Lead}
  %e6 : {Qs.lead.ed(b, _) == Qs.Opens{U32.and(b, 7), 2n, 128, 191}
    : Qs.Lead}
  %e7 : {Qs.lead.ee(b, _) == Qs.Opens{U32.and(b, 7), 2n, 128, 191}
    : Qs.Lead}
  %e8 : {Qs.lead.f0(b, _) == Qs.Opens{U32.and(b, 7), 2n, 128, 191}
    : Qs.Lead}
  %e9 : {Qs.lead.f1(b, _) == Qs.Opens{U32.and(b, 7), 2n, 128, 191}
    : Qs.Lead}
  {==}

def Laws.qs_lead_f4(b, e1, e2, e3, e4, e5, e6, e7, e8, e9, e10):
  %e1 : {Qs.lead.ascii(b, _) == Qs.Opens{4, 2n, 128, 143} : Qs.Lead}
  %e2 : {Qs.lead.low(b, _) == Qs.Opens{4, 2n, 128, 143} : Qs.Lead}
  %e3 : {Qs.lead.two(b, _) == Qs.Opens{4, 2n, 128, 143} : Qs.Lead}
  %e4 : {Qs.lead.e0(b, _) == Qs.Opens{4, 2n, 128, 143} : Qs.Lead}
  %e5 : {Qs.lead.e1(b, _) == Qs.Opens{4, 2n, 128, 143} : Qs.Lead}
  %e6 : {Qs.lead.ed(b, _) == Qs.Opens{4, 2n, 128, 143} : Qs.Lead}
  %e7 : {Qs.lead.ee(b, _) == Qs.Opens{4, 2n, 128, 143} : Qs.Lead}
  %e8 : {Qs.lead.f0(b, _) == Qs.Opens{4, 2n, 128, 143} : Qs.Lead}
  %e9 : {Qs.lead.f1(b, _) == Qs.Opens{4, 2n, 128, 143} : Qs.Lead}
  %e10 : {Qs.lead.f4(_) == Qs.Opens{4, 2n, 128, 143} : Qs.Lead}
  {==}

def Laws.qs_lead_high(b, e1, e2, e3, e4, e5, e6, e7, e8, e9, e10):
  %e1 : {Qs.lead.ascii(b, _) == Qs.Bad{} : Qs.Lead}
  %e2 : {Qs.lead.low(b, _) == Qs.Bad{} : Qs.Lead}
  %e3 : {Qs.lead.two(b, _) == Qs.Bad{} : Qs.Lead}
  %e4 : {Qs.lead.e0(b, _) == Qs.Bad{} : Qs.Lead}
  %e5 : {Qs.lead.e1(b, _) == Qs.Bad{} : Qs.Lead}
  %e6 : {Qs.lead.ed(b, _) == Qs.Bad{} : Qs.Lead}
  %e7 : {Qs.lead.ee(b, _) == Qs.Bad{} : Qs.Lead}
  %e8 : {Qs.lead.f0(b, _) == Qs.Bad{} : Qs.Lead}
  %e9 : {Qs.lead.f1(b, _) == Qs.Bad{} : Qs.Lead}
  %e10 : {Qs.lead.f4(_) == Qs.Bad{} : Qs.Lead}
  {==}

def Laws.qs_need_wide(_cp, _left, _lo, _hi, _c, _k):
  {==}

def Laws.qs_need_last(cp, _lo, _hi, b, k, e):
  %e : {Qs.utf.byte(cp, 0n, b, k, _)
    == SCon{Chr{Qs.utf.add(cp, b)}, k(Qs.Idle{})} : String}
  {==}

def Laws.qs_need_more(cp, l, _lo, _hi, b, k, e):
  %e : {Qs.utf.byte(cp, 1n+l, b, k, _)
    == k(Qs.Need{Qs.utf.add(cp, b), l, 128, 191}) : String}
  {==}

def Laws.qs_need_miss(cp, left, _lo, _hi, b, k, e):
  %e : {Qs.utf.byte(cp, left, b, k, _)
    == SCon{Chr{65533}, Qs.utf.lead(b, k, Qs.lead(b))} : String}
  {==}

def Laws.qs_add(_cp, _b):
  {==}

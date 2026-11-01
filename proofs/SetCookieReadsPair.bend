# proofs of laws/SetCookieReadsPair.bend
import Base
import ../src/qs.bend as Qs
import ../src/echo.bend as Echo
import ../laws/SetCookieReadsPair.bend as Laws

# --- cookies sent back ---

def Laws.ck_pair(_line):
  {==}

def Laws.ck_pair_none(_u, e):
  %e : {Echo.pair.cut(_) == None{} : Maybe<&2, Qs.Kv()>}
  {==}

def Laws.ck_pair_some(_before, _after):
  {==}

def Laws.ck_named_empty(_name, _value):
  {==}

def Laws.ck_named_kept(_name, _value):
  {==}

def Laws.ck_trim(_s):
  {==}

def Laws.ck_lead_nil(_s, e):
  %e : {Echo.wsp.lead(_) == "" : String}
  {==}

def Laws.ck_lead_wsp(h, t, e):
  %e : {Echo.wsp.lead.if(t, h, _, _u => Echo.wsp.lead(t)) == Echo.wsp.lead(t)
    : String}
  {==}

def Laws.ck_lead_other(h, t, e):
  %e : {Echo.wsp.lead.if(t, h, _, _u => Echo.wsp.lead(t)) == SCon{h, t}
    : String}
  {==}

def Laws.ck_wsp(_c):
  {==}

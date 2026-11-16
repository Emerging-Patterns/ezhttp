# proofs of laws/SetCookieParsesBack.bend
import Base
import ../src/cookie.bend as Cookie
import ../laws/SetCookieParsesBack.bend as Laws

def Laws.cookie_parse(_line):
  {==}

def Laws.cookie_parse_parts(_h, _t):
  {==}

def Laws.cookie_from_cut(_pair, _attrs, _before, _after):
  {==}

def Laws.cookie_from_named(_name, _value, _attrs):
  {==}

def Laws.cookie_new(_name, _value):
  {==}

def Laws.cookie_fold_nil(_ps, c, e):
  %e : {Cookie.cookie.fold(_, c) == c : Cookie.Cookie}
  {==}

def Laws.cookie_fold_cons(_h, _t, _c):
  {==}

def Laws.cookie_apply(_c, _piece):
  {==}

def Laws.cookie_apply_named(_c, _piece, _before, _after):
  {==}

def Laws.cookie_apply_flag(_c, _piece):
  {==}

def Laws.cookie_named_expires(_c, _value):
  {==}

def Laws.cookie_named_path(_c, _value):
  {==}

def Laws.cookie_flag_secure(_c):
  {==}

def Laws.cookie_flag_http_only(_c):
  {==}

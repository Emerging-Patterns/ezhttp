# proofs of laws/OctetsDecodeAsUtf8.bend
import Base
import ../src/http.bend as Http
import ../src/qs.bend as Qs
import ../laws/OctetsDecodeAsUtf8.bend as Laws

def Laws.octets_text(_o):
  {==}

def Laws.octets_toks_nil(_s, e):
  %e : {Qs.octets.toks(_) == [] : List<&2, Qs.Tok>}
  {==}

def Laws.octets_toks_cons(_c, _t):
  {==}

def Laws.octets_headers_cons(_name, _value, _t):
  {==}

def Laws.octets_headers_nil(_hs, e):
  %e : {Qs.octets.headers(_) == [] : List<&2, Http.Header>}
  {==}

# proofs of laws/OctetBodiesSentUnchanged.bend
import Base
import ../src/http.bend as Http
import ../laws/OctetBodiesSentUnchanged.bend as Laws
import ./lemmas/HeaderFieldSlots.bend as M1

def Laws.exchange_body_text(_method, _l, _hs, _text):
  {==}

def Laws.exchange_body_empty(_method, _l, _hs):
  {==}

def Laws.exchange_body_octets(_method, _l, _hs, _n, _buf):
  {==}

def Laws.exchange_octets_bad(_method, _why, _hs, _n):
  {==}

def Laws.exchange_octets_loc(_method, _scheme, _host, _port, _path, _hs, _n):
  {==}

def Laws.request_head_at(_method, _secure, _host, _port, _path, _hs, _n):
  {==}

def Laws.fields_n(_host, _hs, _body):
  {==}

def Laws.fields_clen_n(host, hs, n):
  M1.hd.of_fields(Http.FClen{},
      Http.fields.or(Http.fields.of(Http.FHost{}, hs), [Http.H{"Host", host}]),
      Http.fields.or(Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}]),
      Http.fields.or(Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}]),
      Http.fields.of(Http.FOther{}, hs),
      Http.clen.field(n, Nat.is_eq(n, 0n)),
      [], [], [], [],
        Http.clen.field(n,
        Nat.is_eq(n, 0n)),
      M1.hd.or_gone(Http.FClen{}, Http.fields.of(Http.FHost{}, hs),
        [Http.H{"Host", host}],
      M1.hd.disj(Http.FClen{}, Http.FHost{}, {==}, hs), {==}),
      M1.hd.or_gone(Http.FClen{}, Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}],
      M1.hd.disj(Http.FClen{}, Http.FAgent{}, {==}, hs), {==}),
      M1.hd.or_gone(Http.FClen{}, Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}],
      M1.hd.disj(Http.FClen{}, Http.FAccept{}, {==}, hs), {==}),
      Equal.sym(List<&2, Http.Header>,
        Http.fields.of(Http.FClen{}, Http.fields.of(Http.FOther{}, hs)), [],
      M1.hd.disj(Http.FClen{}, Http.FOther{}, {==}, hs)),
      M1.hd.clen_self(n, Nat.is_eq(n, 0n)))

# --- what is sent ---

def Laws.payload_nil(_rest):
  {==}

def Laws.payload_cons(_cp, _t, _rest):
  {==}

def Laws.payload_is(_req):
  {==}

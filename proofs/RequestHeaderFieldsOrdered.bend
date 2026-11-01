# proofs of laws/RequestHeaderFieldsOrdered.bend
import Base
import ../src/http.bend as Http
import ../laws/RequestHeaderFieldsOrdered.bend as Laws
import ./lemmas/HeaderFieldSlots.bend as M1

def Laws.field_host(_name, e):
  %e : {Http.field.of(_) == Http.FHost{} : Http.Field}
  {==}

def Laws.field_agent(_name, e):
  %e : {Http.field.of(_) == Http.FAgent{} : Http.Field}
  {==}

def Laws.field_accept(_name, e):
  %e : {Http.field.of(_) == Http.FAccept{} : Http.Field}
  {==}

def Laws.field_conn(_name, e):
  %e : {Http.field.of(_) == Http.FConn{} : Http.Field}
  {==}

def Laws.field_clen(_name, e):
  %e : {Http.field.of(_) == Http.FClen{} : Http.Field}
  {==}

def Laws.field_other(name, eh, ea, ec, en, el):
  %eh : {Http.field.of.host(_, String.to_lower(name)) == Http.FOther{}
    : Http.Field}
  %ea : {Http.field.of.agent(_, String.to_lower(name)) == Http.FOther{}
    : Http.Field}
  %ec : {Http.field.of.accept(_, String.to_lower(name)) == Http.FOther{}
    : Http.Field}
  %en : {Http.field.of.conn(_, String.to_lower(name)) == Http.FOther{}
    : Http.Field}
  %el : {Http.field.of.clen(_) == Http.FOther{} : Http.Field}
  {==}

def Laws.request_text(_method, _host, _path, _hs, _body):
  {==}

# a list's tail after an empty append is the list
def hd.app_nil(+xs: List<&2,
  Http.Header>) -> {List.append(&2, Http.Header, xs, []) == xs : List<&2,
  Http.Header>}:
  match xs:
    case []:
      {==}
    case h <> t:
      Equal.cong(List<&2, Http.Header>, List<&2, Http.Header>, x => h <> x,
        List.append(&2, Http.Header, t, []), t,
        hd.app_nil(t))

# one step of idem
def hd.idem.put(+f: Http.Field, +k: Bool, +h: Http.Header, +t: List<&2,
  Http.Header>,
  +ek: {k == Http.field.same(f, Http.header.field(h)) : Bool},
  +ih: {Http.fields.of(f, Http.fields.of(f, t))
    == Http.fields.of(f, t) : List<&2, Http.Header>})
  -> {Http.fields.of(f, Http.fields.put(k, h, Http.fields.of(f, t)))
    == Http.fields.put(k, h, Http.fields.of(f, t)) : List<&2, Http.Header>}:
  match k:
    case True{}:
      %ek : {Http.fields.put(_, h, Http.fields.of(f, Http.fields.of(f, t)))
        == h <> Http.fields.of(f, t) : List<&2, Http.Header>}
      Equal.cong(List<&2, Http.Header>, List<&2, Http.Header>, x => h <> x,
        Http.fields.of(f, Http.fields.of(f, t)), Http.fields.of(f, t),
        ih)
    case False{}:
      ih

# the fields of a name among the fields of that name are all of them
def hd.idem(+f: Http.Field, +hs: List<&2, Http.Header>)
  -> {Http.fields.of(f, Http.fields.of(f, hs))
    == Http.fields.of(f, hs) : List<&2, Http.Header>}:
  match hs:
    case []:
      {==}
    case h <> t:
      hd.idem.put(f, Http.field.same(f, Http.header.field(h)), h, t, {==},
        hd.idem(f, t))

# a slot holds itself when the caller's list and the default are all of a
# name
def hd.or_keep(+f: Http.Field, +given: List<&2, Http.Header>, +d: List<&2,
  Http.Header>,
  +eg: {Http.fields.of(f, given) == given : List<&2, Http.Header>},
    +ed: {Http.fields.of(f, d) == d : List<&2, Http.Header>})
  -> {Http.fields.or(given, d)
    == Http.fields.of(f, Http.fields.or(given, d)) : List<&2, Http.Header>}:
  match given:
    case []:
      Equal.sym(List<&2, Http.Header>, Http.fields.of(f, d), d, ed)
    case h <> t:
      Equal.sym(List<&2, Http.Header>, Http.fields.of(f, h <> t), h <> t, eg)

# a computed Content-Length is no other field
def hd.clen_gone(+f: Http.Field,
  +efc: {False{} == Http.field.same(f, Http.FClen{}) : Bool}, +n: Nat,
  +e: Bool) -> {[] == Http.fields.of(f, Http.clen.field(n, e)) : List<&2,
    Http.Header>}:
  match e:
    case True{}:
      {==}
    case False{}:
      %efc : {[]
        == Http.fields.put(_, Http.H{"Content-Length", Nat.show(n)}, [])
        : List<&2, Http.Header>}
      {==}

def Laws.fields_host_caller(host, hs, body, h, t, e):
  Equal.trans(List<&2, Http.Header>,
    Http.fields.of(Http.FHost{}, Http.request.fields(host, hs, body)),
    List.append(&2, Http.Header, h <> t, []), h <> t,
    M1.hd.of_fields(Http.FHost{},
      Http.fields.or(Http.fields.of(Http.FHost{}, hs), [Http.H{"Host", host}]),
      Http.fields.or(Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}]),
      Http.fields.or(Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}]),
      Http.fields.of(Http.FOther{}, hs),
      Http.clen.field(Http.utf8.len(body), Nat.is_eq(Http.utf8.len(body), 0n)),
      h <> t, [], [], [], [],
      Equal.trans(List<&2, Http.Header>, h <> t,
        Http.fields.or(Http.fields.of(Http.FHost{}, hs),
        [Http.H{"Host", host}]),
        Http.fields.of(Http.FHost{},
          Http.fields.or(Http.fields.of(Http.FHost{}, hs),
          [Http.H{"Host", host}])),
        Equal.cong(List<&2, Http.Header>, List<&2, Http.Header>,
          x => Http.fields.or(x, [Http.H{"Host", host}]), h <> t,
          Http.fields.of(Http.FHost{}, hs),
            Equal.sym(List<&2, Http.Header>, Http.fields.of(Http.FHost{}, hs),
            h <> t, e)),
        hd.or_keep(Http.FHost{}, Http.fields.of(Http.FHost{}, hs),
          [Http.H{"Host", host}], hd.idem(Http.FHost{}, hs), {==})),
      M1.hd.or_gone(Http.FHost{}, Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}],
      M1.hd.disj(Http.FHost{}, Http.FAgent{}, {==}, hs), {==}),
      M1.hd.or_gone(Http.FHost{}, Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}],
      M1.hd.disj(Http.FHost{}, Http.FAccept{}, {==}, hs), {==}),
      Equal.sym(List<&2, Http.Header>,
        Http.fields.of(Http.FHost{}, Http.fields.of(Http.FOther{}, hs)), [],
      M1.hd.disj(Http.FHost{}, Http.FOther{}, {==}, hs)),
      hd.clen_gone(Http.FHost{}, {==}, Http.utf8.len(body),
      Nat.is_eq(Http.utf8.len(body), 0n))),
    hd.app_nil(h <> t))

def Laws.fields_host_dflt(host, hs, body, e):
  M1.hd.of_fields(Http.FHost{},
      Http.fields.or(Http.fields.of(Http.FHost{}, hs), [Http.H{"Host", host}]),
      Http.fields.or(Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}]),
      Http.fields.or(Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}]),
      Http.fields.of(Http.FOther{}, hs),
      Http.clen.field(Http.utf8.len(body), Nat.is_eq(Http.utf8.len(body), 0n)),
      [Http.H{"Host", host}], [], [], [], [],
      Equal.trans(List<&2, Http.Header>, [Http.H{"Host", host}],
        Http.fields.or(Http.fields.of(Http.FHost{}, hs),
        [Http.H{"Host", host}]),
        Http.fields.of(Http.FHost{},
          Http.fields.or(Http.fields.of(Http.FHost{}, hs),
          [Http.H{"Host", host}])),
        Equal.cong(List<&2, Http.Header>, List<&2, Http.Header>,
          x => Http.fields.or(x, [Http.H{"Host", host}]), [],
          Http.fields.of(Http.FHost{}, hs),
            Equal.sym(List<&2, Http.Header>, Http.fields.of(Http.FHost{}, hs),
            [], e)),
        hd.or_keep(Http.FHost{}, Http.fields.of(Http.FHost{}, hs),
          [Http.H{"Host", host}], hd.idem(Http.FHost{}, hs), {==})),
      M1.hd.or_gone(Http.FHost{}, Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}],
      M1.hd.disj(Http.FHost{}, Http.FAgent{}, {==}, hs), {==}),
      M1.hd.or_gone(Http.FHost{}, Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}],
      M1.hd.disj(Http.FHost{}, Http.FAccept{}, {==}, hs), {==}),
      Equal.sym(List<&2, Http.Header>,
        Http.fields.of(Http.FHost{}, Http.fields.of(Http.FOther{}, hs)), [],
      M1.hd.disj(Http.FHost{}, Http.FOther{}, {==}, hs)),
      hd.clen_gone(Http.FHost{}, {==}, Http.utf8.len(body),
      Nat.is_eq(Http.utf8.len(body), 0n)))

def Laws.fields_agent_caller(host, hs, body, h, t, e):
  Equal.trans(List<&2, Http.Header>,
    Http.fields.of(Http.FAgent{}, Http.request.fields(host, hs, body)),
    List.append(&2, Http.Header, h <> t, []), h <> t,
    M1.hd.of_fields(Http.FAgent{},
      Http.fields.or(Http.fields.of(Http.FHost{}, hs), [Http.H{"Host", host}]),
      Http.fields.or(Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}]),
      Http.fields.or(Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}]),
      Http.fields.of(Http.FOther{}, hs),
      Http.clen.field(Http.utf8.len(body), Nat.is_eq(Http.utf8.len(body), 0n)),
      [], h <> t, [], [], [],
      M1.hd.or_gone(Http.FAgent{}, Http.fields.of(Http.FHost{}, hs),
        [Http.H{"Host", host}],
      M1.hd.disj(Http.FAgent{}, Http.FHost{}, {==}, hs), {==}),
      Equal.trans(List<&2, Http.Header>, h <> t,
        Http.fields.or(Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}]),
        Http.fields.of(Http.FAgent{},
          Http.fields.or(Http.fields.of(Http.FAgent{}, hs),
          [Http.H{"User-Agent", "ezhttp"}])),
        Equal.cong(List<&2, Http.Header>, List<&2, Http.Header>,
          x => Http.fields.or(x, [Http.H{"User-Agent", "ezhttp"}]), h <> t,
          Http.fields.of(Http.FAgent{}, hs),
            Equal.sym(List<&2, Http.Header>, Http.fields.of(Http.FAgent{}, hs),
            h <> t, e)),
        hd.or_keep(Http.FAgent{}, Http.fields.of(Http.FAgent{}, hs),
          [Http.H{"User-Agent", "ezhttp"}], hd.idem(Http.FAgent{}, hs), {==})),
      M1.hd.or_gone(Http.FAgent{}, Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}],
      M1.hd.disj(Http.FAgent{}, Http.FAccept{}, {==}, hs), {==}),
      Equal.sym(List<&2, Http.Header>,
        Http.fields.of(Http.FAgent{}, Http.fields.of(Http.FOther{}, hs)), [],
      M1.hd.disj(Http.FAgent{}, Http.FOther{}, {==}, hs)),
      hd.clen_gone(Http.FAgent{}, {==}, Http.utf8.len(body),
      Nat.is_eq(Http.utf8.len(body), 0n))),
    hd.app_nil(h <> t))

def Laws.fields_agent_dflt(host, hs, body, e):
  M1.hd.of_fields(Http.FAgent{},
      Http.fields.or(Http.fields.of(Http.FHost{}, hs), [Http.H{"Host", host}]),
      Http.fields.or(Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}]),
      Http.fields.or(Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}]),
      Http.fields.of(Http.FOther{}, hs),
      Http.clen.field(Http.utf8.len(body), Nat.is_eq(Http.utf8.len(body), 0n)),
      [], [Http.H{"User-Agent", "ezhttp"}], [], [], [],
      M1.hd.or_gone(Http.FAgent{}, Http.fields.of(Http.FHost{}, hs),
        [Http.H{"Host", host}],
      M1.hd.disj(Http.FAgent{}, Http.FHost{}, {==}, hs), {==}),
      Equal.trans(List<&2, Http.Header>, [Http.H{"User-Agent", "ezhttp"}],
        Http.fields.or(Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}]),
        Http.fields.of(Http.FAgent{},
          Http.fields.or(Http.fields.of(Http.FAgent{}, hs),
          [Http.H{"User-Agent", "ezhttp"}])),
        Equal.cong(List<&2, Http.Header>, List<&2, Http.Header>,
          x => Http.fields.or(x, [Http.H{"User-Agent", "ezhttp"}]), [],
          Http.fields.of(Http.FAgent{}, hs),
            Equal.sym(List<&2, Http.Header>, Http.fields.of(Http.FAgent{}, hs),
            [], e)),
        hd.or_keep(Http.FAgent{}, Http.fields.of(Http.FAgent{}, hs),
          [Http.H{"User-Agent", "ezhttp"}], hd.idem(Http.FAgent{}, hs), {==})),
      M1.hd.or_gone(Http.FAgent{}, Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}],
      M1.hd.disj(Http.FAgent{}, Http.FAccept{}, {==}, hs), {==}),
      Equal.sym(List<&2, Http.Header>,
        Http.fields.of(Http.FAgent{}, Http.fields.of(Http.FOther{}, hs)), [],
      M1.hd.disj(Http.FAgent{}, Http.FOther{}, {==}, hs)),
      hd.clen_gone(Http.FAgent{}, {==}, Http.utf8.len(body),
      Nat.is_eq(Http.utf8.len(body), 0n)))

def Laws.fields_accept_caller(host, hs, body, h, t, e):
  Equal.trans(List<&2, Http.Header>,
    Http.fields.of(Http.FAccept{}, Http.request.fields(host, hs, body)),
    List.append(&2, Http.Header, h <> t, []), h <> t,
    M1.hd.of_fields(Http.FAccept{},
      Http.fields.or(Http.fields.of(Http.FHost{}, hs), [Http.H{"Host", host}]),
      Http.fields.or(Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}]),
      Http.fields.or(Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}]),
      Http.fields.of(Http.FOther{}, hs),
      Http.clen.field(Http.utf8.len(body), Nat.is_eq(Http.utf8.len(body), 0n)),
      [], [], h <> t, [], [],
      M1.hd.or_gone(Http.FAccept{}, Http.fields.of(Http.FHost{}, hs),
        [Http.H{"Host", host}],
      M1.hd.disj(Http.FAccept{}, Http.FHost{}, {==}, hs), {==}),
      M1.hd.or_gone(Http.FAccept{}, Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}],
      M1.hd.disj(Http.FAccept{}, Http.FAgent{}, {==}, hs), {==}),
      Equal.trans(List<&2, Http.Header>, h <> t,
        Http.fields.or(Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}]),
        Http.fields.of(Http.FAccept{},
          Http.fields.or(Http.fields.of(Http.FAccept{}, hs),
          [Http.H{"Accept", "*/*"}])),
        Equal.cong(List<&2, Http.Header>, List<&2, Http.Header>,
          x => Http.fields.or(x, [Http.H{"Accept", "*/*"}]), h <> t,
          Http.fields.of(Http.FAccept{}, hs),
            Equal.sym(List<&2, Http.Header>,
            Http.fields.of(Http.FAccept{}, hs), h <> t, e)),
        hd.or_keep(Http.FAccept{}, Http.fields.of(Http.FAccept{}, hs),
          [Http.H{"Accept", "*/*"}], hd.idem(Http.FAccept{}, hs), {==})),
      Equal.sym(List<&2, Http.Header>,
        Http.fields.of(Http.FAccept{}, Http.fields.of(Http.FOther{}, hs)), [],
      M1.hd.disj(Http.FAccept{}, Http.FOther{}, {==}, hs)),
      hd.clen_gone(Http.FAccept{}, {==}, Http.utf8.len(body),
      Nat.is_eq(Http.utf8.len(body), 0n))),
    hd.app_nil(h <> t))

def Laws.fields_accept_dflt(host, hs, body, e):
  M1.hd.of_fields(Http.FAccept{},
      Http.fields.or(Http.fields.of(Http.FHost{}, hs), [Http.H{"Host", host}]),
      Http.fields.or(Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}]),
      Http.fields.or(Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}]),
      Http.fields.of(Http.FOther{}, hs),
      Http.clen.field(Http.utf8.len(body), Nat.is_eq(Http.utf8.len(body), 0n)),
      [], [], [Http.H{"Accept", "*/*"}], [], [],
      M1.hd.or_gone(Http.FAccept{}, Http.fields.of(Http.FHost{}, hs),
        [Http.H{"Host", host}],
      M1.hd.disj(Http.FAccept{}, Http.FHost{}, {==}, hs), {==}),
      M1.hd.or_gone(Http.FAccept{}, Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}],
      M1.hd.disj(Http.FAccept{}, Http.FAgent{}, {==}, hs), {==}),
      Equal.trans(List<&2, Http.Header>, [Http.H{"Accept", "*/*"}],
        Http.fields.or(Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}]),
        Http.fields.of(Http.FAccept{},
          Http.fields.or(Http.fields.of(Http.FAccept{}, hs),
          [Http.H{"Accept", "*/*"}])),
        Equal.cong(List<&2, Http.Header>, List<&2, Http.Header>,
          x => Http.fields.or(x, [Http.H{"Accept", "*/*"}]), [],
          Http.fields.of(Http.FAccept{}, hs),
            Equal.sym(List<&2, Http.Header>,
            Http.fields.of(Http.FAccept{}, hs), [], e)),
        hd.or_keep(Http.FAccept{}, Http.fields.of(Http.FAccept{}, hs),
          [Http.H{"Accept", "*/*"}], hd.idem(Http.FAccept{}, hs), {==})),
      Equal.sym(List<&2, Http.Header>,
        Http.fields.of(Http.FAccept{}, Http.fields.of(Http.FOther{}, hs)), [],
      M1.hd.disj(Http.FAccept{}, Http.FOther{}, {==}, hs)),
      hd.clen_gone(Http.FAccept{}, {==}, Http.utf8.len(body),
      Nat.is_eq(Http.utf8.len(body), 0n)))

def Laws.fields_conn(host, hs, body):
  M1.hd.of_fields(Http.FConn{},
      Http.fields.or(Http.fields.of(Http.FHost{}, hs), [Http.H{"Host", host}]),
      Http.fields.or(Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}]),
      Http.fields.or(Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}]),
      Http.fields.of(Http.FOther{}, hs),
      Http.clen.field(Http.utf8.len(body), Nat.is_eq(Http.utf8.len(body), 0n)),
      [], [], [], [], [],
      M1.hd.or_gone(Http.FConn{}, Http.fields.of(Http.FHost{}, hs),
        [Http.H{"Host", host}],
      M1.hd.disj(Http.FConn{}, Http.FHost{}, {==}, hs), {==}),
      M1.hd.or_gone(Http.FConn{}, Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}],
      M1.hd.disj(Http.FConn{}, Http.FAgent{}, {==}, hs), {==}),
      M1.hd.or_gone(Http.FConn{}, Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}],
      M1.hd.disj(Http.FConn{}, Http.FAccept{}, {==}, hs), {==}),
      Equal.sym(List<&2, Http.Header>,
        Http.fields.of(Http.FConn{}, Http.fields.of(Http.FOther{}, hs)), [],
      M1.hd.disj(Http.FConn{}, Http.FOther{}, {==}, hs)),
      hd.clen_gone(Http.FConn{}, {==}, Http.utf8.len(body),
      Nat.is_eq(Http.utf8.len(body), 0n)))

def Laws.fields_clen(host, hs, body):
  M1.hd.of_fields(Http.FClen{},
      Http.fields.or(Http.fields.of(Http.FHost{}, hs), [Http.H{"Host", host}]),
      Http.fields.or(Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}]),
      Http.fields.or(Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}]),
      Http.fields.of(Http.FOther{}, hs),
      Http.clen.field(Http.utf8.len(body), Nat.is_eq(Http.utf8.len(body), 0n)),
      [], [], [], [],
        Http.clen.field(Http.utf8.len(body),
        Nat.is_eq(Http.utf8.len(body), 0n)),
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
      M1.hd.clen_self(Http.utf8.len(body), Nat.is_eq(Http.utf8.len(body), 0n)))

def Laws.fields_other(host, hs, body):
  Equal.trans(List<&2, Http.Header>,
    Http.fields.of(Http.FOther{}, Http.request.fields(host, hs, body)),
    List.append(&2, Http.Header, Http.fields.of(Http.FOther{}, hs), []),
      Http.fields.of(Http.FOther{}, hs),
    M1.hd.of_fields(Http.FOther{},
      Http.fields.or(Http.fields.of(Http.FHost{}, hs), [Http.H{"Host", host}]),
      Http.fields.or(Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}]),
      Http.fields.or(Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}]),
      Http.fields.of(Http.FOther{}, hs),
      Http.clen.field(Http.utf8.len(body), Nat.is_eq(Http.utf8.len(body), 0n)),
      [], [], [], Http.fields.of(Http.FOther{}, hs), [],
      M1.hd.or_gone(Http.FOther{}, Http.fields.of(Http.FHost{}, hs),
        [Http.H{"Host", host}],
      M1.hd.disj(Http.FOther{}, Http.FHost{}, {==}, hs), {==}),
      M1.hd.or_gone(Http.FOther{}, Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}],
      M1.hd.disj(Http.FOther{}, Http.FAgent{}, {==}, hs), {==}),
      M1.hd.or_gone(Http.FOther{}, Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}],
      M1.hd.disj(Http.FOther{}, Http.FAccept{}, {==}, hs), {==}),
      Equal.sym(List<&2, Http.Header>,
        Http.fields.of(Http.FOther{}, Http.fields.of(Http.FOther{}, hs)),
        Http.fields.of(Http.FOther{}, hs),
        hd.idem(Http.FOther{}, hs)),
      hd.clen_gone(Http.FOther{}, {==}, Http.utf8.len(body),
      Nat.is_eq(Http.utf8.len(body), 0n))),
    hd.app_nil(Http.fields.of(Http.FOther{}, hs)))

# string append is associative
def eq.app_assoc(+a: String, +b: String, +c: String)
  -> {String.append(String.append(a, b), c)
    == String.append(a, String.append(b, c)) : String}:
  match a:
    case SNil{}:
      {==}
    case SCon{h, t}:
      Equal.cong(String, String, x => SCon{h, x},
        String.append(String.append(t, b), c),
        String.append(t, String.append(b, c)), eq.app_assoc(t, b, c))

# the lines of an append are the lines of each part
def hd.lines_app(+a: List<&2, Http.Header>, +b: List<&2, Http.Header>)
  -> {Http.headers.lines(List.append(&2, Http.Header, a, b))
    == String.append(Http.headers.lines(a), Http.headers.lines(b)) : String}:
  match a:
    case []:
      {==}
    case +h <> +t:
      Equal.trans(String,
        String.append(Http.header.line(h),
          Http.headers.lines(List.append(&2, Http.Header, t, b))),
        String.append(Http.header.line(h),
          String.append(Http.headers.lines(t), Http.headers.lines(b))),
        String.append(String.append(Http.header.line(h),
          Http.headers.lines(t)), Http.headers.lines(b)),
        Equal.cong(String, String, x => String.append(Http.header.line(h), x),
          Http.headers.lines(List.append(&2, Http.Header, t, b)),
            String.append(Http.headers.lines(t), Http.headers.lines(b)),
            hd.lines_app(t, b)),
        Equal.sym(String,
          String.append(String.append(Http.header.line(h),
          Http.headers.lines(t)), Http.headers.lines(b)),
          String.append(Http.header.line(h),
            String.append(Http.headers.lines(t), Http.headers.lines(b))),
          eq.app_assoc(Http.header.line(h), Http.headers.lines(t),
            Http.headers.lines(b))))

# with none of Host, User-Agent, Accept from the caller and only other
# fields, the request's fields are the defaults, the caller's, Content-Length
def hd.plain_fields(+host: String, +hs: List<&2, Http.Header>, +body: String,
  +eh: {Http.fields.of(Http.FHost{}, hs) == [] : List<&2, Http.Header>},
  +ea: {Http.fields.of(Http.FAgent{}, hs) == [] : List<&2, Http.Header>},
  +ec: {Http.fields.of(Http.FAccept{}, hs) == [] : List<&2, Http.Header>},
  +eo: {Http.fields.of(Http.FOther{}, hs) == hs : List<&2, Http.Header>})
  -> {Http.request.fields(host, hs, body) == Http.H{"Host", host}
    <> Http.H{"User-Agent", "ezhttp"} <> Http.H{"Accept", "*/*"}
    <> Http.H{"Connection", "close"}
    <> List.append(&2, Http.Header, hs,
    Http.clen.field(Http.utf8.len(body),
    Nat.is_eq(Http.utf8.len(body), 0n))) : List<&2, Http.Header>}:
  %Equal.sym(List<&2, Http.Header>, Http.fields.of(Http.FHost{}, hs), [], eh)
    : {List.append(&2, Http.Header, Http.fields.or(_, [Http.H{"Host", host}]),
      List.append(&2, Http.Header,
      Http.fields.or(Http.fields.of(Http.FAgent{}, hs),
      [Http.H{"User-Agent", "ezhttp"}]),
      List.append(&2, Http.Header,
      Http.fields.or(Http.fields.of(Http.FAccept{}, hs),
      [Http.H{"Accept", "*/*"}]), Http.H{"Connection", "close"}
      <> List.append(&2, Http.Header, Http.fields.of(Http.FOther{}, hs),
      Http.clen.field(Http.utf8.len(body),
      Nat.is_eq(Http.utf8.len(body), 0n)))))) == Http.H{"Host", host}
      <> Http.H{"User-Agent", "ezhttp"} <> Http.H{"Accept", "*/*"}
      <> Http.H{"Connection", "close"}
      <> List.append(&2, Http.Header, hs,
      Http.clen.field(Http.utf8.len(body),
      Nat.is_eq(Http.utf8.len(body), 0n))) : List<&2, Http.Header>}
  %Equal.sym(List<&2, Http.Header>, Http.fields.of(Http.FAgent{}, hs), [], ea)
    : {List.append(&2, Http.Header, Http.fields.or([], [Http.H{"Host", host}]),
      List.append(&2, Http.Header,
      Http.fields.or(_, [Http.H{"User-Agent", "ezhttp"}]),
      List.append(&2, Http.Header,
      Http.fields.or(Http.fields.of(Http.FAccept{}, hs),
      [Http.H{"Accept", "*/*"}]), Http.H{"Connection", "close"}
      <> List.append(&2, Http.Header, Http.fields.of(Http.FOther{}, hs),
      Http.clen.field(Http.utf8.len(body),
      Nat.is_eq(Http.utf8.len(body), 0n)))))) == Http.H{"Host", host}
      <> Http.H{"User-Agent", "ezhttp"} <> Http.H{"Accept", "*/*"}
      <> Http.H{"Connection", "close"}
      <> List.append(&2, Http.Header, hs,
      Http.clen.field(Http.utf8.len(body),
      Nat.is_eq(Http.utf8.len(body), 0n))) : List<&2, Http.Header>}
  %Equal.sym(List<&2, Http.Header>, Http.fields.of(Http.FAccept{}, hs), [], ec)
    : {List.append(&2, Http.Header, Http.fields.or([], [Http.H{"Host", host}]),
      List.append(&2, Http.Header,
      Http.fields.or([], [Http.H{"User-Agent", "ezhttp"}]),
      List.append(&2, Http.Header,
      Http.fields.or(_, [Http.H{"Accept", "*/*"}]),
      Http.H{"Connection", "close"}
      <> List.append(&2, Http.Header, Http.fields.of(Http.FOther{}, hs),
      Http.clen.field(Http.utf8.len(body),
      Nat.is_eq(Http.utf8.len(body), 0n)))))) == Http.H{"Host", host}
      <> Http.H{"User-Agent", "ezhttp"} <> Http.H{"Accept", "*/*"}
      <> Http.H{"Connection", "close"}
      <> List.append(&2, Http.Header, hs,
      Http.clen.field(Http.utf8.len(body),
      Nat.is_eq(Http.utf8.len(body), 0n))) : List<&2, Http.Header>}
  %Equal.sym(List<&2, Http.Header>, Http.fields.of(Http.FOther{}, hs), hs, eo)
    : {List.append(&2, Http.Header, Http.fields.or([], [Http.H{"Host", host}]),
      List.append(&2, Http.Header,
      Http.fields.or([], [Http.H{"User-Agent", "ezhttp"}]),
      List.append(&2, Http.Header,
      Http.fields.or([], [Http.H{"Accept", "*/*"}]),
      Http.H{"Connection", "close"}
      <> List.append(&2, Http.Header, _,
      Http.clen.field(Http.utf8.len(body),
      Nat.is_eq(Http.utf8.len(body), 0n)))))) == Http.H{"Host", host}
      <> Http.H{"User-Agent", "ezhttp"} <> Http.H{"Accept", "*/*"}
      <> Http.H{"Connection", "close"}
      <> List.append(&2, Http.Header, hs,
      Http.clen.field(Http.utf8.len(body),
      Nat.is_eq(Http.utf8.len(body), 0n))) : List<&2, Http.Header>}
  {==}

# the plain request's text after `Host: `
def hd.plain_tail(+host: String, +hs: List<&2, Http.Header>, +body: String)
  -> {String.append(String.append(String.append(host, "\r\n"),
    Http.headers.lines(Http.H{"User-Agent", "ezhttp"}
    <> Http.H{"Accept", "*/*"} <> Http.H{"Connection", "close"}
    <> List.append(&2, Http.Header, hs,
    Http.clen.field(Http.utf8.len(body),
    Nat.is_eq(Http.utf8.len(body), 0n))))), "\r\n" ++ body)
    == String.append(host, "\r\n" ++ "User-Agent: ezhttp\r\n"
    ++ "Accept: */*\r\n" ++ "Connection: close\r\n"
    ++ String.append(Http.headers.lines(hs),
    String.append(Http.headers.lines(Http.clen.field(Http.utf8.len(body),
    Nat.is_eq(Http.utf8.len(body), 0n))), "\r\n" ++ body))) : String}:
  Equal.trans(String,
    String.append(String.append(String.append(host, "\r\n"),
    Http.headers.lines(Http.H{"User-Agent", "ezhttp"}
    <> Http.H{"Accept", "*/*"} <> Http.H{"Connection", "close"}
    <> List.append(&2, Http.Header, hs,
    Http.clen.field(Http.utf8.len(body),
    Nat.is_eq(Http.utf8.len(body), 0n))))), "\r\n" ++ body),
    String.append(String.append(host, "\r\n"),
      String.append(Http.headers.lines(Http.H{"User-Agent", "ezhttp"}
      <> Http.H{"Accept", "*/*"} <> Http.H{"Connection", "close"}
      <> List.append(&2, Http.Header, hs,
      Http.clen.field(Http.utf8.len(body),
      Nat.is_eq(Http.utf8.len(body), 0n)))), "\r\n" ++ body)),
    String.append(host, "\r\n" ++ "User-Agent: ezhttp\r\n" ++ "Accept: */*\r\n"
      ++ "Connection: close\r\n"
      ++ String.append(Http.headers.lines(hs),
      String.append(Http.headers.lines(Http.clen.field(Http.utf8.len(body),
      Nat.is_eq(Http.utf8.len(body), 0n))), "\r\n" ++ body))),
    eq.app_assoc(String.append(host, "\r\n"),
      Http.headers.lines(Http.H{"User-Agent", "ezhttp"}
      <> Http.H{"Accept", "*/*"} <> Http.H{"Connection", "close"}
      <> List.append(&2, Http.Header, hs,
      Http.clen.field(Http.utf8.len(body),
      Nat.is_eq(Http.utf8.len(body), 0n)))), "\r\n" ++ body),
    Equal.trans(String,
      String.append(String.append(host, "\r\n"),
      String.append(Http.headers.lines(Http.H{"User-Agent", "ezhttp"}
      <> Http.H{"Accept", "*/*"} <> Http.H{"Connection", "close"}
      <> List.append(&2, Http.Header, hs,
      Http.clen.field(Http.utf8.len(body),
      Nat.is_eq(Http.utf8.len(body), 0n)))), "\r\n" ++ body)),
      String.append(host,
        String.append("\r\n",
        String.append(Http.headers.lines(Http.H{"User-Agent", "ezhttp"}
        <> Http.H{"Accept", "*/*"} <> Http.H{"Connection", "close"}
        <> List.append(&2, Http.Header, hs,
        Http.clen.field(Http.utf8.len(body),
        Nat.is_eq(Http.utf8.len(body), 0n)))), "\r\n" ++ body))),
      String.append(host, "\r\n" ++ "User-Agent: ezhttp\r\n"
        ++ "Accept: */*\r\n" ++ "Connection: close\r\n"
        ++ String.append(Http.headers.lines(hs),
        String.append(Http.headers.lines(Http.clen.field(Http.utf8.len(body),
        Nat.is_eq(Http.utf8.len(body), 0n))), "\r\n" ++ body))),
      eq.app_assoc(host, "\r\n",
        String.append(Http.headers.lines(Http.H{"User-Agent", "ezhttp"}
        <> Http.H{"Accept", "*/*"} <> Http.H{"Connection", "close"}
        <> List.append(&2, Http.Header, hs,
        Http.clen.field(Http.utf8.len(body),
        Nat.is_eq(Http.utf8.len(body), 0n)))), "\r\n" ++ body)),
      Equal.cong(String, String,
        x => String.append(host, "\r\n" ++ "User-Agent: ezhttp\r\n"
        ++ "Accept: */*\r\n" ++ "Connection: close\r\n" ++ x),
        String.append(Http.headers.lines(List.append(&2, Http.Header, hs,
          Http.clen.field(Http.utf8.len(body),
          Nat.is_eq(Http.utf8.len(body), 0n)))), "\r\n" ++ body),
        String.append(Http.headers.lines(hs),
          String.append(Http.headers.lines(Http.clen.field(Http.utf8.len(body),
          Nat.is_eq(Http.utf8.len(body), 0n))), "\r\n" ++ body)),
        Equal.trans(String,
          String.append(Http.headers.lines(List.append(&2, Http.Header, hs,
          Http.clen.field(Http.utf8.len(body),
          Nat.is_eq(Http.utf8.len(body), 0n)))), "\r\n" ++ body),
          String.append(String.append(Http.headers.lines(hs),
            Http.headers.lines(Http.clen.field(Http.utf8.len(body),
            Nat.is_eq(Http.utf8.len(body), 0n)))), "\r\n" ++ body),
          String.append(Http.headers.lines(hs),
            String.append(Http.headers.lines(Http.clen.field(Http.utf8.len(body),
            Nat.is_eq(Http.utf8.len(body), 0n))), "\r\n" ++ body)),
          Equal.cong(String, String, y => String.append(y, "\r\n" ++ body),
            Http.headers.lines(List.append(&2, Http.Header, hs,
            Http.clen.field(Http.utf8.len(body),
            Nat.is_eq(Http.utf8.len(body), 0n)))),
            String.append(Http.headers.lines(hs),
              Http.headers.lines(Http.clen.field(Http.utf8.len(body),
              Nat.is_eq(Http.utf8.len(body), 0n)))),
              hd.lines_app(hs,
              Http.clen.field(Http.utf8.len(body),
              Nat.is_eq(Http.utf8.len(body), 0n)))),
          eq.app_assoc(Http.headers.lines(hs),
            Http.headers.lines(Http.clen.field(Http.utf8.len(body),
            Nat.is_eq(Http.utf8.len(body), 0n))), "\r\n" ++ body)))))

def Laws.request_plain(method, host, path, hs, body, eh, ea, ec, eo):
  Equal.trans(String,
    Http.request(method, host, path, hs, body),
    method ++ " " ++ path ++ " HTTP/1.1\r\n"
      ++ Http.headers.lines(Http.H{"Host", host}
      <> Http.H{"User-Agent", "ezhttp"} <> Http.H{"Accept", "*/*"}
      <> Http.H{"Connection", "close"}
      <> List.append(&2, Http.Header, hs,
      Http.clen.field(Http.utf8.len(body),
      Nat.is_eq(Http.utf8.len(body), 0n)))) ++ "\r\n" ++ body,
    method ++ " " ++ path ++ " HTTP/1.1\r\n" ++ "Host: "
      ++ String.append(host, "\r\n" ++ "User-Agent: ezhttp\r\n"
      ++ "Accept: */*\r\n" ++ "Connection: close\r\n"
      ++ String.append(Http.headers.lines(hs),
      String.append(Http.headers.lines(Http.clen.field(Http.utf8.len(body),
      Nat.is_eq(Http.utf8.len(body), 0n))), "\r\n" ++ body))),
    Equal.cong(List<&2, Http.Header>, String,
      z => method ++ " " ++ path ++ " HTTP/1.1\r\n" ++ Http.headers.lines(z)
        ++ "\r\n" ++ body,
      Http.request.fields(host, hs, body), Http.H{"Host", host}
        <> Http.H{"User-Agent", "ezhttp"} <> Http.H{"Accept", "*/*"}
        <> Http.H{"Connection", "close"}
        <> List.append(&2, Http.Header, hs,
        Http.clen.field(Http.utf8.len(body),
        Nat.is_eq(Http.utf8.len(body), 0n))),
      hd.plain_fields(host, hs, body, eh, ea, ec, eo)),
    Equal.cong(String, String,
      x => method ++ " " ++ path ++ " HTTP/1.1\r\n" ++ "Host: " ++ x,
      String.append(String.append(String.append(host, "\r\n"),
        Http.headers.lines(Http.H{"User-Agent", "ezhttp"}
        <> Http.H{"Accept", "*/*"} <> Http.H{"Connection", "close"}
        <> List.append(&2, Http.Header, hs,
        Http.clen.field(Http.utf8.len(body),
        Nat.is_eq(Http.utf8.len(body), 0n))))), "\r\n" ++ body),
        String.append(host, "\r\n" ++ "User-Agent: ezhttp\r\n"
        ++ "Accept: */*\r\n" ++ "Connection: close\r\n"
        ++ String.append(Http.headers.lines(hs),
        String.append(Http.headers.lines(Http.clen.field(Http.utf8.len(body),
        Nat.is_eq(Http.utf8.len(body), 0n))), "\r\n" ++ body))),
        hd.plain_tail(host, hs, body)))

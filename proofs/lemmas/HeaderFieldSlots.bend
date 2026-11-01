# a request's header fields of one name, slot by slot
import Base
import ../../src/http.bend as Http
import ./BaseEqualities.bend as M1

# two fields field.same calls the same are the same
def hd.same_sound(+a: Http.Field, +b: Http.Field,
  +e: {True{} == Http.field.same(a, b) : Bool}) -> {a == b : Http.Field}:
  match a:
    case Http.FHost{}:
      match b:
        case Http.FHost{}:
          {==}
        case Http.FAgent{}:
          M1.eq.bit.absurd(&2, {Http.FHost{} == Http.FAgent{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FAccept{}:
          M1.eq.bit.absurd(&2, {Http.FHost{} == Http.FAccept{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FConn{}:
          M1.eq.bit.absurd(&2, {Http.FHost{} == Http.FConn{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FClen{}:
          M1.eq.bit.absurd(&2, {Http.FHost{} == Http.FClen{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FOther{}:
          M1.eq.bit.absurd(&2, {Http.FHost{} == Http.FOther{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
    case Http.FAgent{}:
      match b:
        case Http.FHost{}:
          M1.eq.bit.absurd(&2, {Http.FAgent{} == Http.FHost{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FAgent{}:
          {==}
        case Http.FAccept{}:
          M1.eq.bit.absurd(&2, {Http.FAgent{} == Http.FAccept{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FConn{}:
          M1.eq.bit.absurd(&2, {Http.FAgent{} == Http.FConn{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FClen{}:
          M1.eq.bit.absurd(&2, {Http.FAgent{} == Http.FClen{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FOther{}:
          M1.eq.bit.absurd(&2, {Http.FAgent{} == Http.FOther{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
    case Http.FAccept{}:
      match b:
        case Http.FHost{}:
          M1.eq.bit.absurd(&2, {Http.FAccept{} == Http.FHost{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FAgent{}:
          M1.eq.bit.absurd(&2, {Http.FAccept{} == Http.FAgent{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FAccept{}:
          {==}
        case Http.FConn{}:
          M1.eq.bit.absurd(&2, {Http.FAccept{} == Http.FConn{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FClen{}:
          M1.eq.bit.absurd(&2, {Http.FAccept{} == Http.FClen{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FOther{}:
          M1.eq.bit.absurd(&2, {Http.FAccept{} == Http.FOther{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
    case Http.FConn{}:
      match b:
        case Http.FHost{}:
          M1.eq.bit.absurd(&2, {Http.FConn{} == Http.FHost{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FAgent{}:
          M1.eq.bit.absurd(&2, {Http.FConn{} == Http.FAgent{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FAccept{}:
          M1.eq.bit.absurd(&2, {Http.FConn{} == Http.FAccept{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FConn{}:
          {==}
        case Http.FClen{}:
          M1.eq.bit.absurd(&2, {Http.FConn{} == Http.FClen{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FOther{}:
          M1.eq.bit.absurd(&2, {Http.FConn{} == Http.FOther{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
    case Http.FClen{}:
      match b:
        case Http.FHost{}:
          M1.eq.bit.absurd(&2, {Http.FClen{} == Http.FHost{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FAgent{}:
          M1.eq.bit.absurd(&2, {Http.FClen{} == Http.FAgent{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FAccept{}:
          M1.eq.bit.absurd(&2, {Http.FClen{} == Http.FAccept{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FConn{}:
          M1.eq.bit.absurd(&2, {Http.FClen{} == Http.FConn{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FClen{}:
          {==}
        case Http.FOther{}:
          M1.eq.bit.absurd(&2, {Http.FClen{} == Http.FOther{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
    case Http.FOther{}:
      match b:
        case Http.FHost{}:
          M1.eq.bit.absurd(&2, {Http.FOther{} == Http.FHost{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FAgent{}:
          M1.eq.bit.absurd(&2, {Http.FOther{} == Http.FAgent{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FAccept{}:
          M1.eq.bit.absurd(&2, {Http.FOther{} == Http.FAccept{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FConn{}:
          M1.eq.bit.absurd(&2, {Http.FOther{} == Http.FConn{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FClen{}:
          M1.eq.bit.absurd(&2, {Http.FOther{} == Http.FClen{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FOther{}:
          {==}

# one step of of_app: the head kept or not
def hd.of_app.put(+f: Http.Field, +k: Bool, +h: Http.Header, +t: List<&2,
  Http.Header>, +b: List<&2, Http.Header>,
  +ih: {Http.fields.of(f, List.append(&2, Http.Header, t, b))
    == List.append(&2, Http.Header, Http.fields.of(f, t),
    Http.fields.of(f, b)) : List<&2, Http.Header>})
  -> {Http.fields.put(k, h,
    Http.fields.of(f, List.append(&2, Http.Header, t, b)))
    == List.append(&2, Http.Header,
      Http.fields.put(k, h, Http.fields.of(f, t)),
      Http.fields.of(f, b)) : List<&2, Http.Header>}:
  match k:
    case True{}:
      Equal.cong(List<&2, Http.Header>, List<&2, Http.Header>, x => h <> x,
        Http.fields.of(f, List.append(&2, Http.Header, t, b)),
        List.append(&2, Http.Header, Http.fields.of(f, t),
          Http.fields.of(f, b)), ih)
    case False{}:
      ih

# the fields of a name in an append are the ones in each part
def hd.of_app(+f: Http.Field, +a: List<&2, Http.Header>, +b: List<&2,
  Http.Header>)
  -> {Http.fields.of(f, List.append(&2, Http.Header, a, b))
    == List.append(&2, Http.Header, Http.fields.of(f, a),
    Http.fields.of(f, b)) : List<&2, Http.Header>}:
  match a:
    case []:
      {==}
    case h <> t:
      hd.of_app.put(f, Http.field.same(f, Http.header.field(h)), h, t, b,
        hd.of_app(f, t, b))

# of_app, the other way round
def hd.of_app.r(+f: Http.Field, +a: List<&2, Http.Header>, +b: List<&2,
  Http.Header>)
  -> {List.append(&2, Http.Header, Http.fields.of(f, a), Http.fields.of(f, b))
    == Http.fields.of(f, List.append(&2, Http.Header, a, b)) : List<&2,
    Http.Header>}:
  Equal.sym(List<&2, Http.Header>,
    Http.fields.of(f, List.append(&2, Http.Header, a, b)),
    List.append(&2, Http.Header, Http.fields.of(f, a), Http.fields.of(f, b)),
    hd.of_app(f, a, b))

# one step of disj
def hd.disj.put(+f: Http.Field, +g: Http.Field,
  +efg: {False{} == Http.field.same(f, g) : Bool}, +k: Bool, +h: Http.Header,
  +t: List<&2, Http.Header>,
    +ek: {k == Http.field.same(g, Http.header.field(h)) : Bool},
  +ih: {Http.fields.of(f, Http.fields.of(g, t)) == [] : List<&2, Http.Header>})
  -> {Http.fields.of(f, Http.fields.put(k, h, Http.fields.of(g, t)))
    == [] : List<&2, Http.Header>}:
  match k:
    case True{}:
      %Equal.trans(Bool, False{}, Http.field.same(f, g),
        Http.field.same(f, Http.header.field(h)), efg,
        Equal.cong(Http.Field, Bool, y => Http.field.same(f, y), g,
          Http.header.field(h), hd.same_sound(g, Http.header.field(h), ek)))
        : {Http.fields.put(_, h, Http.fields.of(f, Http.fields.of(g, t)))
          == [] : List<&2, Http.Header>}
      ih
    case False{}:
      ih

# the fields of one name among the fields of another are none
def hd.disj(+f: Http.Field, +g: Http.Field,
  +efg: {False{} == Http.field.same(f, g) : Bool}, +hs: List<&2, Http.Header>)
  -> {Http.fields.of(f, Http.fields.of(g, hs)) == [] : List<&2, Http.Header>}:
  match hs:
    case []:
      {==}
    case h <> t:
      hd.disj.put(f, g, efg, Http.field.same(g, Http.header.field(h)), h, t,
        {==}, hd.disj(f, g, efg, t))

# a slot holds none of a name when neither the caller's list nor the default
# does
def hd.or_gone(+f: Http.Field, +given: List<&2, Http.Header>, +d: List<&2,
  Http.Header>,
  +eg: {Http.fields.of(f, given) == [] : List<&2, Http.Header>},
    +ed: {Http.fields.of(f, d) == [] : List<&2, Http.Header>})
  -> {[] == Http.fields.of(f, Http.fields.or(given, d)) : List<&2,
    Http.Header>}:
  match given:
    case []:
      Equal.sym(List<&2, Http.Header>, Http.fields.of(f, d), [], ed)
    case h <> t:
      Equal.sym(List<&2, Http.Header>, Http.fields.of(f, h <> t), [], eg)

# a computed Content-Length is a Content-Length field
def hd.clen_self(+n: Nat, +e: Bool)
  -> {Http.clen.field(n, e)
    == Http.fields.of(Http.FClen{}, Http.clen.field(n, e)) : List<&2,
    Http.Header>}:
  match e:
    case True{}:
      {==}
    case False{}:
      {==}

# the fields of a name in a request's fields, slot by slot
def hd.of_fields(+f: Http.Field, +s1: List<&2, Http.Header>, +s2: List<&2,
  Http.Header>, +s3: List<&2, Http.Header>, +o: List<&2, Http.Header>,
  +c: List<&2, Http.Header>,
  +r1: List<&2, Http.Header>, +r2: List<&2, Http.Header>, +r3: List<&2,
    Http.Header>, +ro: List<&2, Http.Header>, +rc: List<&2, Http.Header>,
  +e1: {r1 == Http.fields.of(f, s1) : List<&2, Http.Header>},
    +e2: {r2 == Http.fields.of(f, s2) : List<&2, Http.Header>},
  +e3: {r3 == Http.fields.of(f, s3) : List<&2, Http.Header>},
    +eo: {ro == Http.fields.of(f, o) : List<&2, Http.Header>},
  +ec: {rc == Http.fields.of(f, c) : List<&2, Http.Header>})
  -> {Http.fields.of(f,
    List.append(&2, Http.Header, s1,
    List.append(&2, Http.Header, s2,
    List.append(&2, Http.Header, s3, Http.H{"Connection", "close"}
    <> List.append(&2, Http.Header, o, c)))))
    == List.append(&2, Http.Header, r1,
      List.append(&2, Http.Header, r2,
      List.append(&2, Http.Header, r3,
      Http.fields.put(Http.field.same(f,
      Http.header.field(Http.H{"Connection", "close"})),
      Http.H{"Connection", "close"},
      List.append(&2, Http.Header, ro, rc))))) : List<&2, Http.Header>}:
  %hd.of_app.r(f, s1,
    List.append(&2, Http.Header, s2,
    List.append(&2, Http.Header, s3, Http.H{"Connection", "close"}
    <> List.append(&2, Http.Header, o, c)))) : {_
    == List.append(&2, Http.Header, r1,
    List.append(&2, Http.Header, r2,
    List.append(&2, Http.Header, r3,
    Http.fields.put(Http.field.same(f,
    Http.header.field(Http.H{"Connection", "close"})),
    Http.H{"Connection", "close"},
    List.append(&2, Http.Header, ro, rc))))) : List<&2, Http.Header>}
  %hd.of_app.r(f, s2,
    List.append(&2, Http.Header, s3, Http.H{"Connection", "close"}
    <> List.append(&2, Http.Header, o, c))) : {List.append(&2, Http.Header,
    Http.fields.of(f, s1), _)
    == List.append(&2, Http.Header, r1,
    List.append(&2, Http.Header, r2,
    List.append(&2, Http.Header, r3,
    Http.fields.put(Http.field.same(f,
    Http.header.field(Http.H{"Connection", "close"})),
    Http.H{"Connection", "close"},
    List.append(&2, Http.Header, ro, rc))))) : List<&2, Http.Header>}
  %hd.of_app.r(f, s3, Http.H{"Connection", "close"}
    <> List.append(&2, Http.Header, o, c))
    : {List.append(&2, Http.Header, Http.fields.of(f, s1),
      List.append(&2, Http.Header, Http.fields.of(f, s2), _))
      == List.append(&2, Http.Header, r1,
      List.append(&2, Http.Header, r2,
      List.append(&2, Http.Header, r3,
      Http.fields.put(Http.field.same(f,
      Http.header.field(Http.H{"Connection", "close"})),
      Http.H{"Connection", "close"},
      List.append(&2, Http.Header, ro, rc))))) : List<&2, Http.Header>}
  %hd.of_app.r(f, o, c)
    : {List.append(&2, Http.Header, Http.fields.of(f, s1),
      List.append(&2, Http.Header, Http.fields.of(f, s2),
      List.append(&2, Http.Header, Http.fields.of(f, s3),
      Http.fields.put(Http.field.same(f,
      Http.header.field(Http.H{"Connection", "close"})),
      Http.H{"Connection", "close"}, _))))
      == List.append(&2, Http.Header, r1,
        List.append(&2, Http.Header, r2,
        List.append(&2, Http.Header, r3,
        Http.fields.put(Http.field.same(f,
        Http.header.field(Http.H{"Connection", "close"})),
        Http.H{"Connection", "close"},
        List.append(&2, Http.Header, ro, rc))))) : List<&2, Http.Header>}
  %e1 : {List.append(&2, Http.Header, _,
    List.append(&2, Http.Header, Http.fields.of(f, s2),
    List.append(&2, Http.Header, Http.fields.of(f, s3),
    Http.fields.put(Http.field.same(f,
    Http.header.field(Http.H{"Connection", "close"})),
    Http.H{"Connection", "close"},
    List.append(&2, Http.Header, Http.fields.of(f, o), Http.fields.of(f, c))))))
    == List.append(&2, Http.Header, r1,
      List.append(&2, Http.Header, r2,
      List.append(&2, Http.Header, r3,
      Http.fields.put(Http.field.same(f,
      Http.header.field(Http.H{"Connection", "close"})),
      Http.H{"Connection", "close"},
      List.append(&2, Http.Header, ro, rc))))) : List<&2, Http.Header>}
  %e2 : {List.append(&2, Http.Header, r1,
    List.append(&2, Http.Header, _,
    List.append(&2, Http.Header, Http.fields.of(f, s3),
    Http.fields.put(Http.field.same(f,
    Http.header.field(Http.H{"Connection", "close"})),
    Http.H{"Connection", "close"},
    List.append(&2, Http.Header, Http.fields.of(f, o), Http.fields.of(f, c))))))
    == List.append(&2, Http.Header, r1,
      List.append(&2, Http.Header, r2,
      List.append(&2, Http.Header, r3,
      Http.fields.put(Http.field.same(f,
      Http.header.field(Http.H{"Connection", "close"})),
      Http.H{"Connection", "close"},
      List.append(&2, Http.Header, ro, rc))))) : List<&2, Http.Header>}
  %e3 : {List.append(&2, Http.Header, r1,
    List.append(&2, Http.Header, r2,
    List.append(&2, Http.Header, _,
    Http.fields.put(Http.field.same(f,
    Http.header.field(Http.H{"Connection", "close"})),
    Http.H{"Connection", "close"},
    List.append(&2, Http.Header, Http.fields.of(f, o), Http.fields.of(f, c))))))
    == List.append(&2, Http.Header, r1,
      List.append(&2, Http.Header, r2,
      List.append(&2, Http.Header, r3,
      Http.fields.put(Http.field.same(f,
      Http.header.field(Http.H{"Connection", "close"})),
      Http.H{"Connection", "close"},
      List.append(&2, Http.Header, ro, rc))))) : List<&2, Http.Header>}
  %eo : {List.append(&2, Http.Header, r1,
    List.append(&2, Http.Header, r2,
    List.append(&2, Http.Header, r3,
    Http.fields.put(Http.field.same(f,
    Http.header.field(Http.H{"Connection", "close"})),
    Http.H{"Connection", "close"},
    List.append(&2, Http.Header, _, Http.fields.of(f, c))))))
    == List.append(&2, Http.Header, r1,
      List.append(&2, Http.Header, r2,
      List.append(&2, Http.Header, r3,
      Http.fields.put(Http.field.same(f,
      Http.header.field(Http.H{"Connection", "close"})),
      Http.H{"Connection", "close"},
      List.append(&2, Http.Header, ro, rc))))) : List<&2, Http.Header>}
  %ec : {List.append(&2, Http.Header, r1,
    List.append(&2, Http.Header, r2,
    List.append(&2, Http.Header, r3,
    Http.fields.put(Http.field.same(f,
    Http.header.field(Http.H{"Connection", "close"})),
    Http.H{"Connection", "close"}, List.append(&2, Http.Header, ro, _)))))
    == List.append(&2, Http.Header, r1,
      List.append(&2, Http.Header, r2,
      List.append(&2, Http.Header, r3,
      Http.fields.put(Http.field.same(f,
      Http.header.field(Http.H{"Connection", "close"})),
      Http.H{"Connection", "close"},
      List.append(&2, Http.Header, ro, rc))))) : List<&2, Http.Header>}
  {==}

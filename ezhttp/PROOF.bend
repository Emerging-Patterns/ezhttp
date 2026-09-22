# ezhttp: the proofs. `bend ezhttp/PROOF.bend` is the gate.
import Base
import ./http.bend as Http
import ./url.bend as Url
import ./body.bend as Body
import ./client.bend as Client
import ./main.bend as Ez
import ./LAWS.bend as Laws

# --- Base facts used by the framing proofs ---

def eq.bool_cmp_self(b: Bool) -> {Bool.cmp(b, b) == EQ{} : Cmp}:
  match b:
    case False{}:
      {==}
    case True{}:
      {==}

def eq.word_cmp_self(n: Nat, w: Word(n)) -> {Word.cmp(n, w, w) == EQ{} : Cmp}:
  match n:
    case 0n:
      match w:
        case WNil{}:
          {==}
    case 1n+p:
      match w:
        case WCon{+b, +t}:
          Equal.trans(Cmp, Word.cmp.fin(b, b, Word.cmp(p, t, t)),
            Word.cmp.fin(b, b, EQ{}), EQ{},
            Equal.cong(Cmp, Cmp, c => Word.cmp.fin(b, b, c),
              Word.cmp(p, t, t), EQ{}, eq.word_cmp_self(p, t)),
            eq.bool_cmp_self(b))

def eq.u32_cmp_self(u: U32) -> {U32.cmp(u, u) == EQ{} : Cmp}:
  match u:
    case U32{+w}:
      eq.word_cmp_self(32n, w)

def eq.char_eq_self(c: Char) -> {Char.is_eq(c, c) == True{} : Bool}:
  match c:
    case Chr{+x}:
      Equal.cong(Cmp, Bool, r => Cmp.is_eq(r), U32.cmp(x, x), EQ{},
        eq.u32_cmp_self(x))

def eq.bit.emp(b: Bool) -> Type:
  match b:
    case False{}:
      Unit
    case True{}:
      Empty

def eq.bit.clash(e: {False{} == True{} : Bool}) -> Empty:
  %e : eq.bit.emp(_)
  Unit{}

def eq.bit.gone(a, -A: Kind(a), e: Empty) -> A:
  match e:

def eq.bit.absurd(a, -A: Kind(a), e: {False{} == True{} : Bool}) -> A:
  eq.bit.gone(a, A, eq.bit.clash(e))

def eq.and.left(u: Bool, v: Bool, e: {Bool.and(u, v) == True{} : Bool})
  -> {u == True{} : Bool}:
  match u:
    case True{}:
      {==}
    case False{}:
      e

def eq.and.right(u: Bool, v: Bool, e: {Bool.and(u, v) == True{} : Bool})
  -> {v == True{} : Bool}:
  match u:
    case True{}:
      e
    case False{}:
      eq.bit.absurd(&2, {v == True{} : Bool}, e)

def eq.not.true(u: Bool, e: {Bool.not(u) == True{} : Bool})
  -> {u == False{} : Bool}:
  match u:
    case True{}:
      eq.bit.absurd(&2, {True{} == False{} : Bool}, e)
    case False{}:
      {==}

def eq.starts_nil(s: String) -> {String.starts_with(s, "") == True{} : Bool}:
  match s:
    case SNil{}:
      {==}
    case SCon{h, t}:
      {==}

def eq.starts_append(a: String, b: String)
  -> {String.starts_with(String.append(a, b), a) == True{} : Bool}:
  match a:
    case SNil{}:
      eq.starts_nil(b)
    case SCon{+h, +t}:
      Equal.trans(Bool,
        String.starts_with.if(String.append(t, b), t, Char.is_eq(h, h)),
        String.starts_with.if(String.append(t, b), t, True{}),
        True{},
        Equal.cong(Bool, Bool,
          x => String.starts_with.if(String.append(t, b), t, x),
          Char.is_eq(h, h), True{}, eq.char_eq_self(h)),
        eq.starts_append(t, b))

# LAW: one step of the UTF-8 partition
law utf8_split.arm:
  for -h: Char
  for -t: String
  for -m: Nat
  for b: Bool
  for ih: {String.append(Http.utf8.take(t, m), Http.utf8.drop(t, m)) == t : String}
  {String.append(
    Http.utf8.take.step(b, h, _u => Http.utf8.take(t, m)),
    Http.utf8.drop.step(b, h, t, _u => Http.utf8.drop(t, m))) == SCon{h, t} : String}

def utf8_split.arm(h, t, m, b, ih):
  match b:
    case True{}:
      {==}
    case False{}:
      Equal.cong(String, String, x => SCon{h, x},
        String.append(Http.utf8.take(t, m), Http.utf8.drop(t, m)), t, ih)

def Laws.utf8_split(s, n):
  match s:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      utf8_split.arm(h, t, Nat.sub(n, Http.utf8.width(Char.to_u32(h))),
        Nat.is_lt(n, Http.utf8.width(Char.to_u32(h))),
        Laws.utf8_split(t, Nat.sub(n, Http.utf8.width(Char.to_u32(h)))))

law lt_zero:
  for n: Nat
  {Nat.is_lt(n, 0n) == False{} : Bool}

def lt_zero(n):
  match n:
    case 0n:
      {==}
    case 1n+p:
      {==}

law lt_add:
  for a: Nat
  for +b: Nat
  {Nat.is_lt(Nat.add(a, b), a) == False{} : Bool}

def lt_add(a, b):
  match a:
    case 0n:
      lt_zero(b)
    case 1n+p:
      lt_add(p, b)

law lt_self:
  for n: Nat
  {Nat.is_lt(n, n) == False{} : Bool}

def lt_self(n):
  match n:
    case 0n:
      {==}
    case 1n+p:
      lt_self(p)

law sub_zero:
  for n: Nat
  {Nat.sub(n, 0n) == n : Nat}

def sub_zero(n):
  match n:
    case 0n:
      {==}
    case 1n+p:
      {==}

law sub_add:
  for a: Nat
  for +b: Nat
  {Nat.sub(Nat.add(a, b), a) == b : Nat}

def sub_add(a, b):
  match a:
    case 0n:
      sub_zero(b)
    case 1n+p:
      sub_add(p, b)

law take_all:
  for +s: String
  {Http.utf8.take(s, Http.utf8.len(s)) == s : String}

def take_all(s):
  match s:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      Equal.trans(String,
        Http.utf8.take(SCon{h, t}, Http.utf8.len(SCon{h, t})),
        SCon{h, Http.utf8.take(t, Nat.sub(
          Nat.add(Http.utf8.width(Char.to_u32(h)), Http.utf8.len(t)),
          Http.utf8.width(Char.to_u32(h))))},
        SCon{h, t},
        Equal.cong(Bool, String,
          b => Http.utf8.take.step(b, h, _u => Http.utf8.take(t, Nat.sub(
            Nat.add(Http.utf8.width(Char.to_u32(h)), Http.utf8.len(t)),
            Http.utf8.width(Char.to_u32(h))))),
          Nat.is_lt(Nat.add(Http.utf8.width(Char.to_u32(h)), Http.utf8.len(t)),
            Http.utf8.width(Char.to_u32(h))),
          False{},
          lt_add(Http.utf8.width(Char.to_u32(h)), Http.utf8.len(t))),
        Equal.trans(String,
          SCon{h, Http.utf8.take(t, Nat.sub(
            Nat.add(Http.utf8.width(Char.to_u32(h)), Http.utf8.len(t)),
            Http.utf8.width(Char.to_u32(h))))},
          SCon{h, Http.utf8.take(t, Http.utf8.len(t))},
          SCon{h, t},
          Equal.cong(Nat, String, m => SCon{h, Http.utf8.take(t, m)},
            Nat.sub(Nat.add(Http.utf8.width(Char.to_u32(h)), Http.utf8.len(t)),
              Http.utf8.width(Char.to_u32(h))),
            Http.utf8.len(t),
            sub_add(Http.utf8.width(Char.to_u32(h)), Http.utf8.len(t))),
          Equal.cong(String, String, x => SCon{h, x},
            Http.utf8.take(t, Http.utf8.len(t)), t, take_all(t))))

def Laws.clen_exact(st, hs, body):
  Equal.trans(Http.Reply,
    Http.parse.clen(st, hs, Http.utf8.len(body), body),
    Http.parse.short(st, hs, Http.utf8.len(body), body, False{}),
    Http.Reply{st, hs, body},
    Equal.cong(Bool, Http.Reply,
      b => Http.parse.short(st, hs, Http.utf8.len(body), body, b),
      Nat.is_lt(Http.utf8.len(body), Http.utf8.len(body)), False{},
      lt_self(Http.utf8.len(body))),
    Equal.cong(String, Http.Reply, x => Http.Reply{st, hs, x},
      Http.utf8.take(body, Http.utf8.len(body)), body, take_all(body)))

def Laws.clen_short(st, hs, n, body, e):
  %e : {Http.parse.short(st, hs, n, body, _)
    == Http.Torn{"the response body stopped before its Content-Length"}
    : Http.Reply}
  {==}

def Laws.path_absolute(ps):
  match ps:
    case []:
      {==}
    case h <> t:
      eq.starts_nil(String.join(t, "/"))

law split_whole.step:
  for +h: Char
  for +t: String
  for +c: Char
  for e: {False{} == Char.is_eq(h, c) : Bool}
  for ih: {String.split(t, c) == [t] : List<&2, String>}
  {String.split(SCon{h, t}, c) == [SCon{h, t}] : List<&2, String>}

def split_whole.step(h, t, c, e, ih):
  %e : {String.split.fin(h, String.split(t, c), _) == [SCon{h, t}]
    : List<&2, String>}
  Equal.cong(List<&2, String>, List<&2, String>,
    r => String.split.fin(h, r, False{}),
    String.split(t, c), [t], ih)

def Laws.split_whole(s, c, e):
  match s:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      split_whole.step(h, t, c,
        Equal.sym(Bool, Char.is_eq(h, c), False{},
          eq.not.true(Char.is_eq(h, c),
            eq.and.left(Bool.not(Char.is_eq(h, c)), Laws.avoids(t, c), e))),
        Laws.split_whole(t, c,
          eq.and.right(Bool.not(Char.is_eq(h, c)), Laws.avoids(t, c), e)))

law split_cut.step:
  for +h: Char
  for +t: String
  for +c: Char
  for r: String
  for e: {False{} == Char.is_eq(h, c) : Bool}
  for ih: {String.split(String.append(t, SCon{c, r}), c) == t <> String.split(r, c)
    : List<&2, String>}
  {String.split(String.append(SCon{h, t}, SCon{c, r}), c)
    == SCon{h, t} <> String.split(r, c) : List<&2, String>}

def split_cut.step(h, t, c, r, e, ih):
  %e : {String.split.fin(h, String.split(String.append(t, SCon{c, r}), c), _)
    == SCon{h, t} <> String.split(r, c) : List<&2, String>}
  Equal.cong(List<&2, String>, List<&2, String>,
    x => String.split.fin(h, x, False{}),
    String.split(String.append(t, SCon{c, r}), c), t <> String.split(r, c), ih)

def Laws.split_cut(s, c, r, e):
  match s:
    case SNil{}:
      Equal.cong(Bool, List<&2, String>,
        x => String.split.fin(c, String.split(r, c), x),
        Char.is_eq(c, c), True{}, eq.char_eq_self(c))
    case SCon{+h, +t}:
      split_cut.step(h, t, c, r,
        Equal.sym(Bool, Char.is_eq(h, c), False{},
          eq.not.true(Char.is_eq(h, c),
            eq.and.left(Bool.not(Char.is_eq(h, c)), Laws.avoids(t, c), e))),
        Laws.split_cut(t, c, r,
          eq.and.right(Bool.not(Char.is_eq(h, c)), Laws.avoids(t, c), e)))

def Laws.dechunk_empty():
  {==}

def Laws.chunks_empty_fuel():
  {==}

def Laws.hexlen_ignores_extension(s, ext, e):
  Equal.trans(Nat,
    Http.hexlen(String.append(s, SCon{';', ext})),
    Http.hex.go(String.trim(s), 0n),
    Http.hexlen(s),
    Equal.cong(List<&2, String>, Nat,
      ps => Http.hex.go(String.trim(Http.first(ps)), 0n),
      String.split(String.append(s, SCon{';', ext}), ';'),
      s <> String.split(ext, ';'),
      Laws.split_cut(s, ';', ext, e)),
    Equal.sym(Nat, Http.hexlen(s), Http.hex.go(String.trim(s), 0n),
      Equal.cong(List<&2, String>, Nat,
        ps => Http.hex.go(String.trim(Http.first(ps)), 0n),
        String.split(s, ';'), [s], Laws.split_whole(s, ';', e))))

def Laws.first_is_first_word(w, r, e):
  Equal.cong(List<&2, String>, String, ps => Http.first(ps),
    String.split(String.append(w, SCon{' ', r}), ' '),
    w <> String.split(r, ' '), Laws.split_cut(w, ' ', r, e))

def Laws.second_is_next_word(w, r, e):
  Equal.cong(List<&2, String>, String, ps => Http.second(ps),
    String.split(String.append(w, SCon{' ', r}), ' '),
    w <> String.split(r, ' '), Laws.split_cut(w, ' ', r, e))

def Laws.request_names_method(method, host, path, hs, body):
  eq.starts_append(method,
    " " ++ path ++ " HTTP/1.1\r\n" ++ "Host: " ++ host ++ "\r\n"
      ++ "User-Agent: ezhttp\r\n" ++ "Accept: */*\r\n"
      ++ "Connection: close\r\n" ++ Http.headers.lines(hs)
      ++ Http.clen.line(Http.utf8.len(body), Nat.is_eq(Http.utf8.len(body), 0n))
      ++ "\r\n" ++ body)

def Laws.get_req_names_path(host, path, hs):
  eq.starts_append(path,
    " HTTP/1.1\r\n" ++ "Host: " ++ host ++ "\r\n" ++ "User-Agent: ezhttp\r\n"
      ++ "Accept: */*\r\n" ++ "Connection: close\r\n" ++ Http.headers.lines(hs)
      ++ Http.clen.line(0n, True{}) ++ "\r\n")

def Laws.head_req_names_path(host, path, hs):
  eq.starts_append(path,
    " HTTP/1.1\r\n" ++ "Host: " ++ host ++ "\r\n" ++ "User-Agent: ezhttp\r\n"
      ++ "Accept: */*\r\n" ++ "Connection: close\r\n" ++ Http.headers.lines(hs)
      ++ Http.clen.line(0n, True{}) ++ "\r\n")

def Laws.post_req_names_path(host, path, hs, body):
  +payload = Body.body.payload(body)
  eq.starts_append(path,
    " HTTP/1.1\r\n" ++ "Host: " ++ host ++ "\r\n" ++ "User-Agent: ezhttp\r\n"
      ++ "Accept: */*\r\n" ++ "Connection: close\r\n" ++ Http.headers.lines(hs)
      ++ Http.clen.line(Http.utf8.len(payload), Nat.is_eq(Http.utf8.len(payload), 0n))
      ++ "\r\n" ++ payload)

def Laws.parse_needs_blank_line(_raw, e):
  %e : {Http.parse.cut(_)
    == Http.Torn{"the response head has no blank line after it"}
    : Http.Reply}
  {==}

def Laws.parse_splits_at_blank_line(_raw, before, after, e):
  %e : {Http.parse.cut(_) == Http.parse.head(String.lines(before), after)
    : Http.Reply}
  {==}

def Laws.unframed_is_rest(_st, _hs, _body):
  {==}

def Laws.head_hit_ignores_case(_h, _name):
  {==}

def Laws.parse_needs_status(ls, body, e):
  %e : {Http.parse.status(_, ls, body)
    == Http.Torn{"the response has no status line"}
    : Http.Reply}
  {==}

def Laws.show_torn_is_marked(why):
  eq.starts_nil(why)

def Laws.show_reply_opens_with_status(status, _hs, body):
  eq.starts_append(U32.show(status), " " ++ body)

def Laws.respond_opens_with_version(status, hs, body):
  eq.starts_append("HTTP/1.1 ",
    U32.show(status) ++ " " ++ Http.reason(status) ++ "\r\n"
      ++ "Connection: close\r\n" ++ Http.headers.lines(hs)
      ++ Http.clen.line(Http.utf8.len(body), Nat.is_eq(Http.utf8.len(body), 0n))
      ++ "\r\n" ++ body)

def Laws.reason_200():
  {==}

def Laws.ask_needs_blank_line(_raw, e):
  %e : {Http.ask.cut(_)
    == Http.Bad{"the request head has no blank line after it"}
    : Http.Request}
  {==}

def Laws.ask_needs_request_line(_body):
  {==}

def Laws.ask_clen_exact(method, target, hs, body):
  Equal.trans(Http.Request,
    Http.ask.clen(method, target, hs, Http.utf8.len(body), body),
    Http.ask.short(method, target, hs, Http.utf8.len(body), body, False{}),
    Http.Request{method, target, hs, body},
    Equal.cong(Bool, Http.Request,
      b => Http.ask.short(method, target, hs, Http.utf8.len(body), body, b),
      Nat.is_lt(Http.utf8.len(body), Http.utf8.len(body)), False{},
      lt_self(Http.utf8.len(body))),
    Equal.cong(String, Http.Request,
      x => Http.Request{method, target, hs, x},
      Http.utf8.take(body, Http.utf8.len(body)), body, take_all(body)))

def Laws.ask_clen_short(method, target, hs, n, body, e):
  %e : {Http.ask.short(method, target, hs, n, body, _)
    == Http.Bad{"the request body stopped before its Content-Length"}
    : Http.Request}
  {==}

def Laws.ask_show_bad_is_marked(why):
  eq.starts_nil(why)

def Laws.dflt_plain(_scheme, e):
  %e : {Bool.pick(U32, _, 443, 80) == 80 : U32}
  {==}

def Laws.dflt_https():
  {==}

def Laws.parse_needs_slashes(scheme, rest, e):
  %e : {Url.parse.body(scheme, rest, _)
    == Url.Bad{scheme ++ ":" ++ rest ++ " has no //"}
    : Url.Loc}
  {==}

def Laws.parse_scheme_first(_url, h, t, e):
  %e : {Url.parse.scheme(_)
    == Url.parse.rest(String.to_lower(h), String.join(t, ":")) : Url.Loc}
  {==}

def Laws.url_show_bad_is_marked(why):
  eq.starts_nil(why)

def Laws.url_show_opens_with_scheme(scheme, host, port, path):
  eq.starts_append(scheme, " " ++ host ++ " " ++ U32.show(port) ++ " " ++ path)

def Laws.parse_url_is_url_parse(_url):
  {==}

def Laws.parse_response_is_http_parse(_raw):
  {==}

def Laws.parse_request_is_ask(_raw):
  {==}

def Laws.format_response_is_respond(_status, _hs, _body):
  {==}

def Laws.empty_body_is_empty():
  {==}

def Laws.text_body_is_text(_s):
  {==}

def Laws.octets_body_is_octets(_bs):
  {==}

def Laws.bearer_is_authorization(_token):
  {==}

def Laws.bearer_is_client_bearer(_token):
  {==}

def Laws.encode_is_body_encode(_s):
  {==}

def Laws.decode_is_body_decode(_s):
  {==}

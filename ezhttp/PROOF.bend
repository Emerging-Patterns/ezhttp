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

def Laws.url_empty_path():
  {==}

def Laws.url_ipv4_host():
  {==}

def Laws.url_ipv4_port():
  {==}

def Laws.url_userinfo_stripped():
  {==}

def Laws.url_query_drops_fragment():
  {==}

def Laws.url_query_on_empty_path():
  {==}

def Laws.url_scheme_lowercased():
  {==}

def Laws.url_https_default_port():
  {==}

def Laws.url_https_explicit_port():
  {==}

def Laws.wire_https_is_tls():
  {==}

def Laws.wire_http_is_tcp():
  {==}

def Laws.request_frames_host_and_close(_method, _host, _path, _hs, _body):
  {==}

def Laws.respond_writes_reason_and_close(_status, _hs, _body):
  {==}

def Laws.put_req_names_path(host, path, hs, body):
  +payload = Body.body.payload(body)
  eq.starts_append(path,
    " HTTP/1.1\r\n" ++ "Host: " ++ host ++ "\r\n" ++ "User-Agent: ezhttp\r\n"
      ++ "Accept: */*\r\n" ++ "Connection: close\r\n" ++ Http.headers.lines(hs)
      ++ Http.clen.line(Http.utf8.len(payload),
        Nat.is_eq(Http.utf8.len(payload), 0n))
      ++ "\r\n" ++ payload)

def Laws.delete_req_names_path(host, path, hs, body):
  +payload = Body.body.payload(body)
  eq.starts_append(path,
    " HTTP/1.1\r\n" ++ "Host: " ++ host ++ "\r\n" ++ "User-Agent: ezhttp\r\n"
      ++ "Accept: */*\r\n" ++ "Connection: close\r\n" ++ Http.headers.lines(hs)
      ++ Http.clen.line(Http.utf8.len(payload),
        Nat.is_eq(Http.utf8.len(payload), 0n))
      ++ "\r\n" ++ payload)

def Laws.options_req_names_path(host, path, hs):
  eq.starts_append(path,
    " HTTP/1.1\r\n" ++ "Host: " ++ host ++ "\r\n" ++ "User-Agent: ezhttp\r\n"
      ++ "Accept: */*\r\n" ++ "Connection: close\r\n" ++ Http.headers.lines(hs)
      ++ Http.clen.line(0n, True{}) ++ "\r\n")

def Laws.method_tokens_are_case_sensitive():
  {==}

def Laws.method_safe_get():
  {==}

def Laws.method_safe_get_lower():
  {==}

def Laws.method_safe_post():
  {==}

def Laws.method_idempotent_put():
  {==}

def Laws.method_idempotent_delete():
  {==}

def Laws.method_idempotent_options():
  {==}

def Laws.method_idempotent_post():
  {==}

def Laws.reason_400():
  {==}

def Laws.reason_404():
  {==}

def Laws.reason_500():
  {==}

def Laws.head_reply_drops_body():
  {==}

def Laws.get_reply_keeps_body():
  {==}

def Laws.head_line_trims():
  {==}

def Laws.head_line_rejects_obs_fold():
  {==}

def Laws.head_line_rejects_continuation():
  {==}

def Laws.ask_rejects_relative_target():
  {==}

def Laws.ask_origin_form_keeps_query():
  {==}

def Laws.parse_rejects_cl_and_te():
  {==}

def Laws.ask_rejects_disagreeing_cl():
  {==}

def Laws.parse_rejects_non_hex_chunk():
  {==}

def Laws.dechunk_two_chunks():
  {==}

def Laws.dechunk_wiki():
  {==}

def Laws.parse_clen_takes_prefix():
  {==}

def Laws.parse_chunked_body():
  {==}

def Laws.token_ok_plain():
  {==}

def Laws.token_ok_space():
  {==}

def Laws.token_ok_tab():
  {==}

def Laws.b64_empty():
  {==}

def Laws.b64_f():
  {==}

def Laws.b64_fo():
  {==}

def Laws.b64_foo():
  {==}

def Laws.basic_user_pass():
  {==}

def Laws.basic_is_client_basic(_user, _password):
  {==}

def Laws.cookie_line_attributes():
  {==}

def Laws.cookie_parse_round_trip():
  {==}

def Laws.cookie_rejects_empty_name():
  {==}

def Laws.cookie_request_joins():
  {==}

def Laws.cookie_default_path_dir():
  {==}

def Laws.cookie_default_path_root():
  {==}

def Laws.cookie_default_path_trailing():
  {==}

def Laws.cookie_receive_host_only():
  {==}

def Laws.cookie_domain_suffix():
  {==}

def Laws.cookie_domain_not_suffix():
  {==}

def Laws.cookie_domain_ip_suffix():
  {==}

def Laws.cookie_domain_ip_exact():
  {==}

def Laws.cookie_path_prefix():
  {==}

def Laws.cookie_path_not_prefix():
  {==}

def Laws.cookie_secure_needs_tls():
  {==}

def Laws.cookie_secure_on_tls():
  {==}

def Laws.cookie_max_age_zero():
  {==}

def Laws.cookie_max_age_open():
  {==}

def Laws.cookie_session_alive():
  {==}

def Laws.set_cookie_is_cookie_set(_c):
  {==}

def Laws.parse_cookie_is_parse(_line):
  {==}

def Laws.cookie_header_is_request(_cs):
  {==}

def Laws.cache_directive_case():
  {==}

def Laws.cache_directives():
  {==}

def Laws.fresh_max_age_zero():
  {==}

def Laws.fresh_max_age_open():
  {==}

def Laws.fresh_max_age_limit():
  {==}

def Laws.fresh_no_cache():
  {==}

def Laws.fresh_no_store():
  {==}

def Laws.fresh_public_only():
  {==}

def Laws.cache_note_expires():
  {==}

def Laws.fresh_max_age_overrides_expires():
  {==}

def Laws.cache_max_age_present():
  {==}

def Laws.cache_control_is_parse(_value):
  {==}

def Laws.fresh_is_cache_fresh(_value, _age):
  {==}

def Laws.cors_credentials_reflect_origin():
  {==}

def Laws.cors_star_without_credentials():
  {==}

def Laws.cors_explicit_origin():
  {==}

def Laws.cors_refused_origin():
  {==}

def Laws.cors_vary_specific():
  {==}

def Laws.cors_vary_star():
  {==}

def Laws.cors_vary_empty():
  {==}

def Laws.cors_preflight_allowed():
  {==}

def Laws.cors_preflight_method_denied():
  {==}

def Laws.cors_simple_reflects():
  {==}

def Laws.cors_simple_star():
  {==}

def Laws.cors_simple_refused():
  {==}

def Laws.cors_on_preflight():
  {==}

def Laws.cors_origin_header():
  {==}

def Laws.cors_request_method_header():
  {==}

def Laws.cors_request_headers_header():
  {==}

def Laws.cors_reply_is_on(_cfg, _req, _reply):
  {==}
def Laws.url_http_default_port():
  {==}

def Laws.url_query_keeps_question():
  {==}

def Laws.url_fragment_hides_query():
  {==}

def Laws.url_userinfo_last_at():
  {==}

def Laws.url_trailing_slash():
  {==}

def Laws.url_bad_port_uses_default():
  {==}

def Laws.post_writes_content_length():
  {==}

def Laws.get_omits_content_length():
  {==}

def Laws.reason_201():
  {==}

def Laws.reason_204():
  {==}

def Laws.reason_405():
  {==}

def Laws.reason_unknown_empty():
  {==}

def Laws.respond_204_drops_body():
  {==}

def Laws.respond_304_drops_body():
  {==}

def Laws.respond_200_keeps_body():
  {==}

def Laws.method_safe_head():
  {==}

def Laws.method_safe_options():
  {==}

def Laws.method_safe_put():
  {==}

def Laws.method_safe_delete():
  {==}

def Laws.method_idempotent_get():
  {==}

def Laws.method_idempotent_head():
  {==}

def Laws.method_idempotent_patch():
  {==}

def Laws.headers_find_ignores_case():
  {==}

def Laws.headers_find_missing():
  {==}

def Laws.headers_find_first():
  {==}

def Laws.ask_keeps_field_name_spelling():
  {==}

def Laws.parse_equal_content_lengths():
  {==}

def Laws.ask_rejects_cl_and_te():
  {==}

def Laws.parse_rejects_disagreeing_cl():
  {==}

def Laws.ask_equal_content_lengths():
  {==}

def Laws.parse_chunked_ignores_case():
  {==}

def Laws.dechunk_ignores_extension():
  {==}

def Laws.dechunk_stops_at_zero():
  {==}

def Laws.dechunk_only_last():
  {==}

def Laws.hexlen_extension_and_case():
  {==}

def Laws.hexlen_alpha():
  {==}

def Laws.digits_read_decimal():
  {==}

def Laws.digits_read_rejects_junk():
  {==}

def Laws.ask_options_asterisk():
  {==}

def Laws.ask_get_asterisk_rejected():
  {==}

def Laws.ask_rejects_absolute_form():
  {==}

def Laws.b64_user_pass():
  {==}

def Laws.token_ok_newline():
  {==}

def Laws.cookie_samesite_strict():
  {==}

def Laws.cookie_samesite_none():
  {==}

def Laws.cookie_samesite_unknown():
  {==}

def Laws.cookie_max_age_ignores_junk():
  {==}

def Laws.cookie_domain_lowercased():
  {==}

def Laws.cookie_path_identical():
  {==}

def Laws.cookie_path_root():
  {==}

def Laws.cookie_path_longer_cookie():
  {==}

def Laws.cookie_path_slash_prefix():
  {==}

def Laws.cookie_default_path_one_slash():
  {==}

def Laws.cookie_ipv4_literal():
  {==}

def Laws.cookie_ipv4_name():
  {==}

def Laws.cookie_send_host_only():
  {==}

def Laws.cookie_send_other_host():
  {==}

def Laws.cookie_send_unset_domain():
  {==}

def Laws.cookie_insecure_on_tcp():
  {==}

def Laws.cookie_max_age_one():
  {==}

def Laws.cache_ignores_s_maxage():
  {==}

def Laws.cache_max_age_ignores_junk():
  {==}

def Laws.cache_no_cache_alone():
  {==}

def Laws.cache_private_alone():
  {==}

def Laws.fresh_max_age_one():
  {==}

def Laws.cors_preflight_header_case():
  {==}

def Laws.cors_preflight_origin_denied():
  {==}

def Laws.cors_preflight_header_denied():
  {==}

def Laws.cors_credentials_explicit_origin():
  {==}

def Laws.cors_get_is_not_preflight():
  {==}

def Laws.cors_preflight_star():
  {==}

# ezhttp: the proofs. `bend PROOF.bend` is the gate.
import Base
import ./src/http.bend as Http
import ./src/url.bend as Url
import ./src/body.bend as Body
import ./src/step.bend as Step
import ./src/pct.bend as Pct
import ./src/wirespec.bend as Spec
import ./src/html.bend as Html
import ./src/redirect.bend as Redirect
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
        String.starts_with.go.if(t, String.append(t, b), Char.is_eq(h, h)),
        String.starts_with.go.if(t, String.append(t, b), True{}),
        True{},
        Equal.cong(Bool, Bool,
          x => String.starts_with.go.if(t, String.append(t, b), x),
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

def Laws.bearer_is_authorization(_token):
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

def Laws.json_string_is_text_body():
  {==}

def Laws.json_parse_string():
  {==}

def Laws.json_parse_rejects():
  {==}

def Laws.cors_preflight_star():
  {==}

# --- the server's decisions ---

def Laws.step_bad(_why):
  {==}

def Laws.step_call(_method, _target, _hs, _body):
  {==}

def Laws.shape_head(_status, _hs, _body):
  {==}

def Laws.shape_other(_method, e, reply):
  match reply:
    case Http.Torn{why}:
      %e : {Http.reply.for.pick(Http.Torn{why}, _) == Http.Torn{why}
        : Http.Reply}
      {==}
    case Http.Reply{status, hs, body}:
      %e : {Http.reply.for.pick(Http.Reply{status, hs, body}, _)
        == Http.Reply{status, hs, body} : Http.Reply}
      {==}

def Laws.respond_204(_hs, _body):
  {==}

def Laws.respond_304(_hs, _body):
  {==}

def Laws.respond_other(status, e, hs, body):
  %e : {Http.respond.of.body(status, hs, body, _)
    == Http.respond(status, hs, body) : String}
  {==}

def Laws.lost_failed(_a, _phase, _code, _why):
  {==}

def Laws.lost_kept(_a, _phase, _value):
  {==}

def Laws.lost_send(_code, _why, _left):
  {==}

def Laws.lost_sent(_done):
  {==}

# --- percent-encoding (SPEC.md HTTP-URL) ---

def Laws.quote_nil(_slash):
  {==}

def Laws.quote_cons(_slash, _c, _t):
  {==}

def Laws.one_unreserved(slash, c, e, rest):
  %e : {Pct.one.of(c, rest, Bool.or(_, Bool.and(U32.is_eq(c, 47), slash)))
    == SCon{Chr{c}, rest} : String}
  {==}

def Laws.one_escaped(_slash, c, e, rest):
  %e : {Pct.one.of(c, rest, _) == Pct.pct(Pct.utf8(c), rest) : String}
  {==}

def Laws.pct_nil(_rest):
  {==}

def Laws.pct_cons(_b, _bs, _rest):
  {==}

def Laws.hex_digit(n, e):
  %e : {Chr{Bool.pick(U32, _, U32.add(48, n), U32.add(55, n))}
    == Chr{U32.add(48, n)} : Char}
  {==}

def Laws.hex_letter(n, e):
  %e : {Chr{Bool.pick(U32, _, U32.add(48, n), U32.add(55, n))}
    == Chr{U32.add(55, n)} : Char}
  {==}

def Laws.utf8_one(c, e):
  %e : {Pct.utf8.one(c, _) == [c] : List<&2, U32>}
  {==}

def Laws.utf8_two(c, e1, e2):
  %e1 : {Pct.utf8.one(c, _) == [U32.or(192, U32.shrn(c, 6n)),
    U32.or(128, U32.and(c, 63))] : List<&2, U32>}
  %e2 : {Pct.utf8.two(c, _) == [U32.or(192, U32.shrn(c, 6n)),
    U32.or(128, U32.and(c, 63))] : List<&2, U32>}
  {==}

def Laws.utf8_three(c, e1, e2, e3):
  %e1 : {Pct.utf8.one(c, _) == [U32.or(224, U32.shrn(c, 12n)),
    U32.or(128, U32.and(U32.shrn(c, 6n), 63)),
    U32.or(128, U32.and(c, 63))] : List<&2, U32>}
  %e2 : {Pct.utf8.two(c, _) == [U32.or(224, U32.shrn(c, 12n)),
    U32.or(128, U32.and(U32.shrn(c, 6n), 63)),
    U32.or(128, U32.and(c, 63))] : List<&2, U32>}
  %e3 : {Pct.utf8.three(c, _) == [U32.or(224, U32.shrn(c, 12n)),
    U32.or(128, U32.and(U32.shrn(c, 6n), 63)),
    U32.or(128, U32.and(c, 63))] : List<&2, U32>}
  {==}

def Laws.utf8_four(c, e1, e2, e3):
  %e1 : {Pct.utf8.one(c, _) == [U32.or(240, U32.shrn(c, 18n)),
    U32.or(128, U32.and(U32.shrn(c, 12n), 63)),
    U32.or(128, U32.and(U32.shrn(c, 6n), 63)),
    U32.or(128, U32.and(c, 63))] : List<&2, U32>}
  %e2 : {Pct.utf8.two(c, _) == [U32.or(240, U32.shrn(c, 18n)),
    U32.or(128, U32.and(U32.shrn(c, 12n), 63)),
    U32.or(128, U32.and(U32.shrn(c, 6n), 63)),
    U32.or(128, U32.and(c, 63))] : List<&2, U32>}
  %e3 : {Pct.utf8.three(c, _) == [U32.or(240, U32.shrn(c, 18n)),
    U32.or(128, U32.and(U32.shrn(c, 12n), 63)),
    U32.or(128, U32.and(U32.shrn(c, 6n), 63)),
    U32.or(128, U32.and(c, 63))] : List<&2, U32>}
  {==}

def Laws.path_keeps_slash(_rest):
  {==}

def Laws.component_escapes_slash(_rest):
  {==}

def Laws.component_is_path_elsewhere(c, e, rest):
  %e : {Pct.one.of(c, rest, Bool.or(Pct.unreserved(c), Bool.and(_, False{})))
    == Pct.one.of(c, rest, Bool.or(Pct.unreserved(c), Bool.and(_, True{})))
    : String}
  {==}

def Laws.frame_kept(slash, c, e, rest):
  %e : {Laws.framed(slash, Pct.one.of(c, rest, _), 0n)
    == Laws.framed(slash, rest, 0n) : Bool}
  %e : {Bool.and(Bool.or(_, U32.is_eq(c, 37)),
    Laws.framed(slash, rest,
      Bool.pick(Nat, _, 0n, Bool.pick(Nat, U32.is_eq(c, 37), 2n, 0n))))
    == Laws.framed(slash, rest, 0n) : Bool}
  {==}

# LAW: one %XX triple whose nibbles are hex digits stays in the frame
law frame_bytes.step:
  for +slash: Bool
  for +b: U32
  for t: List<&2, U32>
  for +rest: String
  for e1: {True{} == Laws.hexdig(Pct.hex(U32.shrn(b, 4n))) : Bool}
  for e2: {True{} == Laws.hexdig(Pct.hex(U32.and(b, 15))) : Bool}
  for ih: {Laws.framed(slash, Pct.pct(t, rest), 0n)
    == Laws.framed(slash, rest, 0n) : Bool}
  {Laws.framed(slash, Pct.pct(b <> t, rest), 0n)
    == Laws.framed(slash, rest, 0n) : Bool}

def frame_bytes.step(slash, b, t, rest, e1, e2, ih):
  %e1 : {Bool.and(_, Bool.and(Laws.hexdig(Pct.hex(U32.and(b, 15))),
    Laws.framed(slash, Pct.pct(t, rest), 0n)))
    == Laws.framed(slash, rest, 0n) : Bool}
  %e2 : {Bool.and(_, Laws.framed(slash, Pct.pct(t, rest), 0n))
    == Laws.framed(slash, rest, 0n) : Bool}
  ih

def Laws.frame_bytes(slash, bs, e, rest):
  match bs:
    case []:
      {==}
    case +b <> +t:
      frame_bytes.step(slash, b, t, rest,
        Equal.sym(Bool, Laws.hexdig(Pct.hex(U32.shrn(b, 4n))), True{},
          eq.and.left(Laws.hexdig(Pct.hex(U32.shrn(b, 4n))),
            Bool.and(Laws.hexdig(Pct.hex(U32.and(b, 15))), Laws.hexes(t)), e)),
        Equal.sym(Bool, Laws.hexdig(Pct.hex(U32.and(b, 15))), True{},
          eq.and.left(Laws.hexdig(Pct.hex(U32.and(b, 15))), Laws.hexes(t),
            eq.and.right(Laws.hexdig(Pct.hex(U32.shrn(b, 4n))),
              Bool.and(Laws.hexdig(Pct.hex(U32.and(b, 15))), Laws.hexes(t)),
              e))),
        Laws.frame_bytes(slash, t,
          eq.and.right(Laws.hexdig(Pct.hex(U32.and(b, 15))), Laws.hexes(t),
            eq.and.right(Laws.hexdig(Pct.hex(U32.shrn(b, 4n))),
              Bool.and(Laws.hexdig(Pct.hex(U32.and(b, 15))), Laws.hexes(t)),
              e)),
          rest))

# LAW: one character stays in the frame, kept or escaped
law frame_char:
  for +slash: Bool
  for +c: U32
  for +k: Bool
  for +ek: {k == Pct.safe(slash, c) : Bool}
  for +h: {Bool.or(k, Laws.hexes(Pct.utf8(c))) == True{} : Bool}
  for +rest: String
  {Laws.framed(slash, Pct.one(slash, c, rest), 0n)
    == Laws.framed(slash, rest, 0n) : Bool}

def frame_char(slash, c, k, ek, h, rest):
  match k:
    case True{}:
      Laws.frame_kept(slash, c, ek, rest)
    case False{}:
      %ek : {Laws.framed(slash, Pct.one.of(c, rest, _), 0n)
        == Laws.framed(slash, rest, 0n) : Bool}
      Laws.frame_bytes(slash, Pct.utf8(c), h, rest)

def Laws.frame_quote(slash, str, e):
  match str:
    case SNil{}:
      {==}
    case SCon{Chr{+c}, +t}:
      Equal.trans(Bool,
        Laws.framed(slash, Pct.one(slash, c, Pct.quote(slash, t)), 0n),
        Laws.framed(slash, Pct.quote(slash, t), 0n),
        True{},
        frame_char(slash, c, Pct.safe(slash, c), {==},
          eq.and.left(Bool.or(Pct.safe(slash, c), Laws.hexes(Pct.utf8(c))),
            Laws.nibbles(slash, t), e),
          Pct.quote(slash, t)),
        Laws.frame_quote(slash, t,
          eq.and.right(Bool.or(Pct.safe(slash, c), Laws.hexes(Pct.utf8(c))),
            Laws.nibbles(slash, t), e)))

# --- the client's timeout (SPEC.md HTTP-CLI) ---

# binary digits read back are the word they were written from
def bits.round(n: Nat, w: Word(n))
  -> {Spec.wire.bits.read(n, Spec.wire.bits(n, w)) == w : Word(n)}:
  match n:
    case 0n:
      match w:
        case WNil{}:
          {==}
    case 1n+p:
      match w:
        case WCon{b, t}:
          match b:
            case True{}:
              Equal.cong(Word(p), Word(1n+p), x => WCon{True{}, x},
                Spec.wire.bits.read(p, Spec.wire.bits(p, t)), t,
                bits.round(p, t))
            case False{}:
              Equal.cong(Word(p), Word(1n+p), x => WCon{False{}, x},
                Spec.wire.bits.read(p, Spec.wire.bits(p, t)), t,
                bits.round(p, t))

# binary digits hold no character other than 0 and 1
def bits.avoid(n: Nat, w: Word(n), +c: Char,
  +e0: {False{} == Char.is_eq('0', c) : Bool},
  +e1: {False{} == Char.is_eq('1', c) : Bool})
  -> {Laws.avoids(Spec.wire.bits(n, w), c) == True{} : Bool}:
  match n:
    case 0n:
      match w:
        case WNil{}:
          {==}
    case 1n+p:
      match w:
        case WCon{b, t}:
          match b:
            case True{}:
              %e1 : {Bool.and(Bool.not(_), Laws.avoids(Spec.wire.bits(p, t), c))
                == True{} : Bool}
              bits.avoid(p, t, c, e0, e1)
            case False{}:
              %e0 : {Bool.and(Bool.not(_), Laws.avoids(Spec.wire.bits(p, t), c))
                == True{} : Bool}
              bits.avoid(p, t, c, e0, e1)

# the first line of a timed spec holds no newline
def head.avoid(secure: Bool, w: Word(32n))
  -> {Laws.avoids(Spec.wire.head(secure, U32{w}), '\n') == True{} : Bool}:
  match secure:
    case True{}:
      bits.avoid(32n, w, '\n', {==}, {==})
    case False{}:
      bits.avoid(32n, w, '\n', {==}, {==})

# the scheme word holds no space
def scheme.avoid(secure: Bool)
  -> {Laws.avoids(Spec.wire.scheme(secure), ' ') == True{} : Bool}:
  match secure:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.spec_timed_ms(secure, ms, host, port, req):
  match ms:
    case U32{+w}:
      Equal.trans(U32,
        Spec.wire.ms(Spec.wire.spec.timed(secure, U32{w}, host, port, req)),
        Spec.wire.ms.words(String.split(Spec.wire.head(secure, U32{w}), ' ')),
        U32{w},
        Equal.cong(List<&2, String>, U32,
          ls => Spec.wire.ms.words(String.split(Spec.wire.line(ls), ' ')),
          String.split(String.append(Spec.wire.head(secure, U32{w}),
            SCon{'\n', Spec.wire.rest(host, port, req)}), '\n'),
          Spec.wire.head(secure, U32{w})
            <> String.split(Spec.wire.rest(host, port, req), '\n'),
          Laws.split_cut(Spec.wire.head(secure, U32{w}), '\n',
            Spec.wire.rest(host, port, req), head.avoid(secure, w))),
        Equal.trans(U32,
          Spec.wire.ms.words(String.split(Spec.wire.head(secure, U32{w}), ' ')),
          Spec.wire.ms.words(Spec.wire.scheme(secure)
            <> String.split(Spec.wire.bits(32n, w), ' ')),
          U32{w},
          Equal.cong(List<&2, String>, U32, ls => Spec.wire.ms.words(ls),
            String.split(String.append(Spec.wire.scheme(secure),
              SCon{' ', Spec.wire.bits(32n, w)}), ' '),
            Spec.wire.scheme(secure)
              <> String.split(Spec.wire.bits(32n, w), ' '),
            Laws.split_cut(Spec.wire.scheme(secure), ' ',
              Spec.wire.bits(32n, w), scheme.avoid(secure))),
          Equal.trans(U32,
            Spec.wire.ms.words(Spec.wire.scheme(secure)
              <> String.split(Spec.wire.bits(32n, w), ' ')),
            U32{Spec.wire.bits.read(32n, Spec.wire.bits(32n, w))},
            U32{w},
            Equal.cong(List<&2, String>, U32,
              ls => Spec.wire.ms.words(Spec.wire.scheme(secure) <> ls),
              String.split(Spec.wire.bits(32n, w), ' '),
              [Spec.wire.bits(32n, w)],
              Laws.split_whole(Spec.wire.bits(32n, w), ' ',
                bits.avoid(32n, w, ' ', {==}, {==}))),
            Equal.cong(Word(32n), U32, x => U32{x},
              Spec.wire.bits.read(32n, Spec.wire.bits(32n, w)), w,
              bits.round(32n, w)))))

def Laws.spec_plain_ms(secure, _host, _port, _req):
  match secure:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.spec_timed_lines(_secure, _ms, _host, _port, _req):
  {==}

def Laws.spec_plain_lines(_secure, _host, _port, _req):
  {==}

def Laws.why_late(_why):
  {==}

def Laws.why_other(_n, e, why):
  %e : {Spec.wire.why.of(why, _) == why : String}
  {==}

def Laws.why_none(_why):
  {==}

def Laws.why_late_timed_out(why):
  eq.starts_append("timed out: ", why)

# --- redirects (SPEC.md HTTP-REDIR) ---

def Laws.redir_go(_status, e, _n, url, loc, next, et):
  %e : {Redirect.redirect.on(url, loc, _) == Redirect.Go{next} : Redirect.Hop}
  %et : {Redirect.redirect.hop(_) == Redirect.Go{next} : Redirect.Hop}
  {==}

# a response whose Location has no target stops, redirect or not
law redir_no_target.on:
  for url: String
  for +loc: String
  for moved: Bool
  for et: {None{} == Redirect.redirect.target(url, loc) : Maybe<&2, String>}
  {Redirect.redirect.on(url, loc, moved) == Redirect.Stop{} : Redirect.Hop}

def redir_no_target.on(_url, _loc, moved, et):
  match moved:
    case True{}:
      %et : {Redirect.redirect.hop(_) == Redirect.Stop{} : Redirect.Hop}
      {==}
    case False{}:
      {==}

def Laws.redir_no_target(status, left, url, loc, et):
  match left:
    case 0n:
      {==}
    case 1n+p:
      redir_no_target.on(url, loc, Redirect.redirect.is(status), et)

def Laws.redir_plan_location(_left, _url, _status, _hs):
  {==}

def Laws.redir_other(_status, e, left, url, loc):
  match left:
    case 0n:
      {==}
    case 1n+p:
      %e : {Redirect.redirect.on(url, loc, _) == Redirect.Stop{}
        : Redirect.Hop}
      {==}

def Laws.redir_zero(_url, _status, _loc):
  {==}

def Laws.target_absolute(url, loc, e):
  %e : {Redirect.redirect.target.of(url, loc, _) == Some{loc}
    : Maybe<&2, String>}
  {==}

# --- HTML escaping (SPEC.md HTTP-HTML) ---

def Laws.html_escape_onto(_s):
  {==}

def Laws.html_nil(_rest):
  {==}

def Laws.html_cons(_c, _t, _rest):
  {==}

def Laws.html_amp(_rest):
  {==}

def Laws.html_lt(_rest):
  {==}

def Laws.html_gt(_rest):
  {==}

def Laws.html_dq(_rest):
  {==}

def Laws.html_sq(_rest):
  {==}

def Laws.html_other(c, e1, e2, e3, e4, e5, rest):
  %e1 : {Html.one.amp(c, rest, _) == SCon{c, rest} : String}
  %e2 : {Html.one.lt(c, rest, _) == SCon{c, rest} : String}
  %e3 : {Html.one.gt(c, rest, _) == SCon{c, rest} : String}
  %e4 : {Html.one.dq(c, rest, _) == SCon{c, rest} : String}
  %e5 : {Html.one.sq(c, rest, _) == SCon{c, rest} : String}
  {==}

# LAW: a character none of the five stays in the frame
law frame.sq:
  for +c: Char
  for rest: String
  for k: Bool
  for ek: {k == Char.is_eq(c, '\'') : Bool}
  for ea: {False{} == Char.is_eq(c, '&') : Bool}
  for el: {False{} == Char.is_eq(c, '<') : Bool}
  for eg: {False{} == Char.is_eq(c, '>') : Bool}
  for ed: {False{} == Char.is_eq(c, '"') : Bool}
  {Laws.html.framed(Html.one.sq(c, rest, k), Laws.Out{})
    == Laws.html.framed(rest, Laws.Out{}) : Bool}

def frame.sq(c, rest, k, ek, ea, el, eg, ed):
  match k:
    case True{}:
      {==}
    case False{}:
      %ea : {Bool.and(Laws.ent.out.ok(Char.is_eq(c, '<'), Char.is_eq(c, '>'),
        Char.is_eq(c, '"'), Char.is_eq(c, '\'')),
        Laws.html.framed(rest, Laws.ent.out.next(_)))
        == Laws.html.framed(rest, Laws.Out{}) : Bool}
      %el : {Bool.and(Laws.ent.out.ok(_, Char.is_eq(c, '>'),
        Char.is_eq(c, '"'), Char.is_eq(c, '\'')),
        Laws.html.framed(rest, Laws.Out{}))
        == Laws.html.framed(rest, Laws.Out{}) : Bool}
      %eg : {Bool.and(Laws.ent.out.ok(False{}, _,
        Char.is_eq(c, '"'), Char.is_eq(c, '\'')),
        Laws.html.framed(rest, Laws.Out{}))
        == Laws.html.framed(rest, Laws.Out{}) : Bool}
      %ed : {Bool.and(Laws.ent.out.ok(False{}, False{}, _,
        Char.is_eq(c, '\'')),
        Laws.html.framed(rest, Laws.Out{}))
        == Laws.html.framed(rest, Laws.Out{}) : Bool}
      %ek : {Bool.and(Laws.ent.out.ok(False{}, False{}, False{}, _),
        Laws.html.framed(rest, Laws.Out{}))
        == Laws.html.framed(rest, Laws.Out{}) : Bool}
      {==}

# LAW: a character that is not `&`, `<` or `>` stays in the frame
law frame.dq:
  for +c: Char
  for rest: String
  for k: Bool
  for ek: {k == Char.is_eq(c, '"') : Bool}
  for ea: {False{} == Char.is_eq(c, '&') : Bool}
  for el: {False{} == Char.is_eq(c, '<') : Bool}
  for eg: {False{} == Char.is_eq(c, '>') : Bool}
  {Laws.html.framed(Html.one.dq(c, rest, k), Laws.Out{})
    == Laws.html.framed(rest, Laws.Out{}) : Bool}

def frame.dq(c, rest, k, ek, ea, el, eg):
  match k:
    case True{}:
      {==}
    case False{}:
      frame.sq(c, rest, Char.is_eq(c, '\''), {==}, ea, el, eg, ek)

# LAW: a character that is not `&` or `<` stays in the frame
law frame.gt:
  for +c: Char
  for rest: String
  for k: Bool
  for ek: {k == Char.is_eq(c, '>') : Bool}
  for ea: {False{} == Char.is_eq(c, '&') : Bool}
  for el: {False{} == Char.is_eq(c, '<') : Bool}
  {Laws.html.framed(Html.one.gt(c, rest, k), Laws.Out{})
    == Laws.html.framed(rest, Laws.Out{}) : Bool}

def frame.gt(c, rest, k, ek, ea, el):
  match k:
    case True{}:
      {==}
    case False{}:
      frame.dq(c, rest, Char.is_eq(c, '"'), {==}, ea, el, ek)

# LAW: a character that is not `&` stays in the frame
law frame.lt:
  for +c: Char
  for rest: String
  for k: Bool
  for ek: {k == Char.is_eq(c, '<') : Bool}
  for ea: {False{} == Char.is_eq(c, '&') : Bool}
  {Laws.html.framed(Html.one.lt(c, rest, k), Laws.Out{})
    == Laws.html.framed(rest, Laws.Out{}) : Bool}

def frame.lt(c, rest, k, ek, ea):
  match k:
    case True{}:
      {==}
    case False{}:
      frame.gt(c, rest, Char.is_eq(c, '>'), {==}, ea, ek)

# LAW: one escaped character stays in the frame
law frame.amp:
  for +c: Char
  for rest: String
  for k: Bool
  for ek: {k == Char.is_eq(c, '&') : Bool}
  {Laws.html.framed(Html.one.amp(c, rest, k), Laws.Out{})
    == Laws.html.framed(rest, Laws.Out{}) : Bool}

def frame.amp(c, rest, k, ek):
  match k:
    case True{}:
      {==}
    case False{}:
      frame.lt(c, rest, Char.is_eq(c, '<'), {==}, ek)

# LAW: an escaped string stays in the frame, whatever follows it
law frame.onto:
  for s: String
  for +rest: String
  {Laws.html.framed(Html.escape.onto(s, rest), Laws.Out{})
    == Laws.html.framed(rest, Laws.Out{}) : Bool}

def frame.onto(s, rest):
  match s:
    case SNil{}:
      {==}
    case SCon{+c, +t}:
      Equal.trans(Bool,
        Laws.html.framed(Html.one(c, Html.escape.onto(t, rest)), Laws.Out{}),
        Laws.html.framed(Html.escape.onto(t, rest), Laws.Out{}),
        Laws.html.framed(rest, Laws.Out{}),
        frame.amp(c, Html.escape.onto(t, rest), Char.is_eq(c, '&'), {==}),
        frame.onto(t, rest))

def Laws.html_frame(s):
  frame.onto(s, "")

# --- reason-phrases (SPEC.md HTTP-SRV-5) ---

def Laws.reason_phrases(_code):
  {==}

def Laws.reason_in_nil(_code):
  {==}

def Laws.reason_in_hit(code, _c, text, t, e):
  %e : {Http.reason.pick(text, _, _u => Http.reason.in(t, code)) == text
    : String}
  {==}

def Laws.reason_in_miss(code, _c, text, t, e):
  %e : {Http.reason.pick(text, _, _u => Http.reason.in(t, code))
    == Http.reason.in(t, code) : String}
  {==}

# --- the client's requests (SPEC.md HTTP-CLI-4 to 6) ---

def Laws.host_http_default(_host):
  {==}

def Laws.host_https_default(_host):
  {==}

def Laws.host_http_other(host, port, e):
  %e : {Http.authority.of(host, port, _) == host ++ ":" ++ U32.show(port)
    : String}
  {==}

def Laws.host_https_other(host, port, e):
  %e : {Http.authority.of(host, port, _) == host ++ ":" ++ U32.show(port)
    : String}
  {==}

def Laws.request_at(_method, _secure, _host, _port, _path, _hs, _body):
  {==}

def Laws.exchange_bad(_method, _why, _hs, _body):
  {==}

def Laws.exchange_loc(_method, _scheme, _host, _port, _path, _hs, _body):
  {==}

def Laws.whole_open(method, _raw, e):
  %e : {Http.whole.cut(String.eq(method, "HEAD"), _) == False{} : Bool}
  {==}

def Laws.whole_head(method, _raw, before, after, e):
  %e : {Http.whole.cut(String.eq(method, "HEAD"), _)
    == Http.whole.of(Http.frame(Bool.or(String.eq(method, "HEAD"),
      Http.status.bare(Http.status.of(String.lines(before)))),
      Http.head.go(String.lines(before), "transfer-encoding"),
      Http.head.values(String.lines(before), "content-length")), after)
    : Bool}
  {==}

def Laws.status_of(_ls):
  {==}

def Laws.status_bare_some(_n):
  {==}

def Laws.status_bare_none(_m, e):
  %e : {Http.status.bare(_) == False{} : Bool}
  {==}

def Laws.frame_bare(_te, _lens):
  {==}

def Laws.frame_chunked(_te, lens, e):
  %e : {Http.frame.te(lens, _) == Http.Chunked{} : Http.Frame}
  {==}

def Laws.frame_sized(_te, lens, e1, e2, n, e3):
  %e1 : {Http.frame.te(lens, _) == Http.Sized{n} : Http.Frame}
  %e2 : {Http.frame.agree(lens, _) == Http.Sized{n} : Http.Frame}
  %e3 : {Http.frame.sized(_) == Http.Sized{n} : Http.Frame}
  {==}

def Laws.frame_disagree(_te, lens, e1, e2):
  %e1 : {Http.frame.te(lens, _) == Http.Closed{} : Http.Frame}
  %e2 : {Http.frame.agree(lens, _) == Http.Closed{} : Http.Frame}
  {==}

def Laws.frame_unsized(_te, lens, e1, e2, e3):
  %e1 : {Http.frame.te(lens, _) == Http.Closed{} : Http.Frame}
  %e2 : {Http.frame.agree(lens, _) == Http.Closed{} : Http.Frame}
  %e3 : {Http.frame.sized(_) == Http.Closed{} : Http.Frame}
  {==}

def Laws.whole_bare(_body):
  {==}

def Laws.whole_sized(_n, _body):
  {==}

def Laws.whole_chunked(_body):
  {==}

def Laws.whole_closed(_body):
  {==}

def Laws.ended_fuel(_c):
  {==}

def Laws.ended_open(_f):
  {==}

def Laws.ended_bad(f, before, after, e):
  %e : {Http.chunks.ended.hex(before, after, _,
    cut => Http.chunks.ended(f, cut)) == True{} : Bool}
  {==}

def Laws.ended_last(f, before, after, e1, e2):
  %e1 : {Http.chunks.ended.hex(before, after, _,
    cut => Http.chunks.ended(f, cut)) == Http.chunks.trailer(after) : Bool}
  %e2 : {Http.chunks.ended.size(after, Http.hexlen(before), _,
    cut => Http.chunks.ended(f, cut)) == Http.chunks.trailer(after) : Bool}
  {==}

def Laws.ended_next(f, before, after, e1, e2, e3):
  %e1 : {Http.chunks.ended.hex(before, after, _,
    cut => Http.chunks.ended(f, cut)) == Http.chunks.ended(f, Http.divide(Http.utf8.drop(after,
      Nat.add(Http.hexlen(before), 2n)), "\r\n")) : Bool}
  %e2 : {Http.chunks.ended.size(after, Http.hexlen(before), _,
    cut => Http.chunks.ended(f, cut)) == Http.chunks.ended(f, Http.divide(Http.utf8.drop(after,
      Nat.add(Http.hexlen(before), 2n)), "\r\n")) : Bool}
  %e3 : {Http.chunks.ended.data(after, Http.hexlen(before), _,
    cut => Http.chunks.ended(f, cut)) == Http.chunks.ended(f, Http.divide(Http.utf8.drop(after,
      Nat.add(Http.hexlen(before), 2n)), "\r\n")) : Bool}
  {==}

def Laws.ended_short(f, before, after, e1, e2, e3):
  %e1 : {Http.chunks.ended.hex(before, after, _,
    cut => Http.chunks.ended(f, cut)) == False{} : Bool}
  %e2 : {Http.chunks.ended.size(after, Http.hexlen(before), _,
    cut => Http.chunks.ended(f, cut)) == False{} : Bool}
  %e3 : {Http.chunks.ended.data(after, Http.hexlen(before), _,
    cut => Http.chunks.ended(f, cut)) == False{} : Bool}
  {==}

def Laws.trailer_ended(_after):
  {==}

def Laws.chunk_ready(_after, _n):
  {==}

def Laws.opened_fail(got, e):
  %e : {Spec.wire.opened.of(got, _) == Spec.Refused{got} : Spec.Opened}
  {==}

def eq.drop_zero(s: String) -> {String.drop(s, 0n) == s : String}:
  match s:
    case SNil{}:
      {==}
    case SCon{h, t}:
      {==}

def Laws.opened_conn(n, text, e):
  dz = Equal.sym(String, String.drop(text, 0n), text, eq.drop_zero(text))
  %dz : {Spec.wire.opened.conn(U32.read(_)) == Spec.Open{n} : Spec.Opened}
  %e : {Spec.wire.opened.conn(_) == Spec.Open{n} : Spec.Opened}
  {==}

def Laws.read_fail(method, acc, got, e):
  %e : {Spec.wire.read.of(method, acc, got, _) == Spec.Heard{got}
    : Spec.Read}
  {==}

def Laws.read_closed(_method, _acc):
  {==}

def Laws.read_whole(method, acc, text, e1, e2):
  dz = Equal.sym(String, String.drop(text, 0n), text, eq.drop_zero(text))
  %dz : {Spec.wire.read.got(method, acc, _, String.is_empty(_)) == Spec.Heard{"0\n" ++ (acc ++ text)}
    : Spec.Read}
  %e1 : {Spec.wire.read.got(method, acc, text, _)
    == Spec.Heard{"0\n" ++ (acc ++ text)} : Spec.Read}
  %e2 : {Spec.wire.read.whole(acc ++ text, _)
    == Spec.Heard{"0\n" ++ (acc ++ text)} : Spec.Read}
  {==}

def Laws.read_more(method, acc, text, e1, e2):
  dz = Equal.sym(String, String.drop(text, 0n), text, eq.drop_zero(text))
  %dz : {Spec.wire.read.got(method, acc, _, String.is_empty(_)) == Spec.Again{acc ++ text}
    : Spec.Read}
  %e1 : {Spec.wire.read.got(method, acc, text, _) == Spec.Again{acc ++ text}
    : Spec.Read}
  %e2 : {Spec.wire.read.whole(acc ++ text, _) == Spec.Again{acc ++ text}
    : Spec.Read}
  {==}

# --- redirect targets (SPEC.md HTTP-REDIR-3 to 5) ---

def Laws.target_bad(url, loc, e1, _why, e2):
  %e1 : {Redirect.redirect.target.of(url, loc, _) == None{}
    : Maybe<&2, String>}
  %e2 : {Redirect.redirect.at(_, loc) == None{} : Maybe<&2, String>}
  {==}

def Laws.target_against(url, loc, e1, scheme, host, port, path, e2):
  %e1 : {Redirect.redirect.target.of(url, loc, _)
    == Redirect.redirect.against(scheme, host, port, path, loc,
      Redirect.redirect.sort(loc)) : Maybe<&2, String>}
  %e2 : {Redirect.redirect.at(_, loc)
    == Redirect.redirect.against(scheme, host, port, path, loc,
      Redirect.redirect.sort(loc)) : Maybe<&2, String>}
  {==}

def Laws.against_net(_scheme, _host, _port, _path, _loc):
  {==}

def Laws.against_abs(_scheme, _host, _port, _path, _loc):
  {==}

def Laws.against_stay(_scheme, _host, _port, _path, _loc):
  {==}

def Laws.against_query(_scheme, _host, _port, _path, _loc):
  {==}

def Laws.against_rel(_scheme, _host, _port, _path, _loc):
  {==}

def Laws.sort_net(loc, e):
  %e : {Redirect.redirect.sort.of(_, String.starts_with(loc, "/"),
    Redirect.redirect.stays(loc), String.starts_with(loc, "?")) == Redirect.Net{} : Redirect.Sort}
  {==}

def Laws.sort_abs(loc, e1, e2):
  %e1 : {Redirect.redirect.sort.of(_, String.starts_with(loc, "/"),
    Redirect.redirect.stays(loc), String.starts_with(loc, "?")) == Redirect.Abs{} : Redirect.Sort}
  %e2 : {Redirect.redirect.sort.abs(_, Redirect.redirect.stays(loc),
    String.starts_with(loc, "?")) == Redirect.Abs{} : Redirect.Sort}
  {==}

def Laws.sort_stay(loc, e1, e2, e3):
  %e1 : {Redirect.redirect.sort.of(_, String.starts_with(loc, "/"),
    Redirect.redirect.stays(loc), String.starts_with(loc, "?")) == Redirect.Stay{} : Redirect.Sort}
  %e2 : {Redirect.redirect.sort.abs(_, Redirect.redirect.stays(loc),
    String.starts_with(loc, "?")) == Redirect.Stay{} : Redirect.Sort}
  %e3 : {Redirect.redirect.sort.stay(_, String.starts_with(loc, "?")) == Redirect.Stay{} : Redirect.Sort}
  {==}

def Laws.sort_query(loc, e1, e2, e3, e4):
  %e1 : {Redirect.redirect.sort.of(_, String.starts_with(loc, "/"),
    Redirect.redirect.stays(loc), String.starts_with(loc, "?")) == Redirect.Query{} : Redirect.Sort}
  %e2 : {Redirect.redirect.sort.abs(_, Redirect.redirect.stays(loc),
    String.starts_with(loc, "?")) == Redirect.Query{} : Redirect.Sort}
  %e3 : {Redirect.redirect.sort.stay(_, String.starts_with(loc, "?")) == Redirect.Query{} : Redirect.Sort}
  %e4 : {Redirect.redirect.sort.rel(_) == Redirect.Query{} : Redirect.Sort}
  {==}

def Laws.sort_rel(loc, e1, e2, e3, e4):
  %e1 : {Redirect.redirect.sort.of(_, String.starts_with(loc, "/"),
    Redirect.redirect.stays(loc), String.starts_with(loc, "?")) == Redirect.Rel{} : Redirect.Sort}
  %e2 : {Redirect.redirect.sort.abs(_, Redirect.redirect.stays(loc),
    String.starts_with(loc, "?")) == Redirect.Rel{} : Redirect.Sort}
  %e3 : {Redirect.redirect.sort.stay(_, String.starts_with(loc, "?")) == Redirect.Rel{} : Redirect.Sort}
  %e4 : {Redirect.redirect.sort.rel(_) == Redirect.Rel{} : Redirect.Sort}
  {==}

def Laws.stays_on(_loc):
  {==}

def Laws.schemed_nil(s, e):
  match s:
    case SNil{}:
      {==}
    case SCon{h, t}:
      eq.bit.absurd(&2, {Redirect.redirect.schemed(SCon{h, t}) == False{} : Bool},
        Equal.sym(Bool, True{}, False{}, e))

def Laws.schemed_colon(_t):
  {==}

def Laws.schemed_stop(c, t, e):
  %e : {Redirect.redirect.schemed.at(_, Char.is_eq(c, ':'),
    _u => Redirect.redirect.schemed(t)) == False{} : Bool}
  {==}

def Laws.schemed_other(c, t, e1, e2):
  %e2 : {Redirect.redirect.schemed.at(_, Char.is_eq(c, ':'),
    _u => Redirect.redirect.schemed(t)) == Redirect.redirect.schemed(t) : Bool}
  %e1 : {Redirect.redirect.schemed.colon(_, _u => Redirect.redirect.schemed(t))
    == Redirect.redirect.schemed(t) : Bool}
  {==}

def Laws.schemed_end(_c):
  {==}

def Laws.split_query(loc, p, q, e):
  %e : {Redirect.redirect.split.of(_, Url.frag.drop(loc))
    == Redirect.Ref{p, "?" ++ q} : Redirect.Ref}
  {==}

def Laws.split_plain(loc, e):
  %e : {Redirect.redirect.split.of(_, Url.frag.drop(loc))
    == Redirect.Ref{Url.frag.drop(loc), ""} : Redirect.Ref}
  {==}

def Laws.abs_of(_path, _query):
  {==}

def Laws.rel_of(_base, _path, _query):
  {==}

def Laws.base_path(_path):
  {==}

def Laws.hier_first(_h, _t):
  {==}

def Laws.init_nil(ss, e):
  match ss:
    case []:
      {==}
    case h <> t:
      eq.bit.absurd(&2, {Redirect.redirect.init(h <> t) == [] : List<&2, String>},
        Equal.sym(Bool, True{}, False{}, e))

def Laws.init_cons(_s, _t):
  {==}

def Laws.init_last(_s):
  {==}

def Laws.init_keep(_s, _u, _r):
  {==}

def Laws.clean_path(_ss):
  {==}

def Laws.dots_nil(_out):
  {==}

def Laws.dots_dot(s, t, out, e):
  %e : {Redirect.redirect.dots.one(_, String.eq(s, ".."),
    List.is_empty(&2, String, t), s, out, o => Redirect.redirect.dots(t, o))
    == Redirect.redirect.dots(t,
      Redirect.redirect.dots.end(List.is_empty(&2, String, t), out))
    : List<&2, String>}
  {==}

def Laws.dots_up(s, t, out, e1, e2):
  %e1 : {Redirect.redirect.dots.one(_, String.eq(s, ".."),
    List.is_empty(&2, String, t), s, out, o => Redirect.redirect.dots(t, o))
    == Redirect.redirect.dots(t,
      Redirect.redirect.dots.end(List.is_empty(&2, String, t),
        Redirect.redirect.pop(out))) : List<&2, String>}
  %e2 : {Redirect.redirect.dots.up(_, List.is_empty(&2, String, t), s, out,
    o => Redirect.redirect.dots(t, o))
    == Redirect.redirect.dots(t,
      Redirect.redirect.dots.end(List.is_empty(&2, String, t),
        Redirect.redirect.pop(out))) : List<&2, String>}
  {==}

def Laws.dots_seg(s, t, out, e1, e2):
  %e1 : {Redirect.redirect.dots.one(_, String.eq(s, ".."),
    List.is_empty(&2, String, t), s, out, o => Redirect.redirect.dots(t, o))
    == Redirect.redirect.dots(t, s <> out) : List<&2, String>}
  %e2 : {Redirect.redirect.dots.up(_, List.is_empty(&2, String, t), s, out,
    o => Redirect.redirect.dots(t, o))
    == Redirect.redirect.dots(t, s <> out) : List<&2, String>}
  {==}

def Laws.dots_last(_out):
  {==}

def Laws.dots_inner(_out):
  {==}

def Laws.pop_nil(out, e):
  match out:
    case []:
      {==}
    case h <> t:
      eq.bit.absurd(&2, {Redirect.redirect.pop(h <> t) == [] : List<&2, String>},
        Equal.sym(Bool, True{}, False{}, e))

def Laws.pop_cons(_s, _t):
  {==}

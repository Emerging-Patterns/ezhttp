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
import ./src/form.bend as Form
import ./src/qs.bend as Qs
import ./src/unescape.bend as Ref
import ./src/entities.bend as Ents
import ./src/echo.bend as Echo
import bend-kit-bytes@0.3.2.0/bytes.bend as Bytes
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
  for ih: {String.append(Http.octs.take(t, m), Http.octs.drop(t, m)) == t : String}
  {String.append(
    Http.octs.take.step(b, h, _u => Http.octs.take(t, m)),
    Http.octs.drop.step(b, h, t, _u => Http.octs.drop(t, m))) == SCon{h, t} : String}

def utf8_split.arm(h, t, m, b, ih):
  match b:
    case True{}:
      {==}
    case False{}:
      Equal.cong(String, String, x => SCon{h, x},
        String.append(Http.octs.take(t, m), Http.octs.drop(t, m)), t, ih)

def Laws.utf8_split(s, n):
  match s:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      utf8_split.arm(h, t, Nat.sub(n, Http.octs.width(Char.to_u32(h))),
        Nat.is_lt(n, Http.octs.width(Char.to_u32(h))),
        Laws.utf8_split(t, Nat.sub(n, Http.octs.width(Char.to_u32(h)))))

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
  {Http.octs.take(s, Http.octs.len(s)) == s : String}

def take_all(s):
  match s:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      Equal.trans(String,
        Http.octs.take(SCon{h, t}, Http.octs.len(SCon{h, t})),
        SCon{h, Http.octs.take(t, Nat.sub(
          Nat.add(Http.octs.width(Char.to_u32(h)), Http.octs.len(t)),
          Http.octs.width(Char.to_u32(h))))},
        SCon{h, t},
        Equal.cong(Bool, String,
          b => Http.octs.take.step(b, h, _u => Http.octs.take(t, Nat.sub(
            Nat.add(Http.octs.width(Char.to_u32(h)), Http.octs.len(t)),
            Http.octs.width(Char.to_u32(h))))),
          Nat.is_lt(Nat.add(Http.octs.width(Char.to_u32(h)), Http.octs.len(t)),
            Http.octs.width(Char.to_u32(h))),
          False{},
          lt_add(Http.octs.width(Char.to_u32(h)), Http.octs.len(t))),
        Equal.trans(String,
          SCon{h, Http.octs.take(t, Nat.sub(
            Nat.add(Http.octs.width(Char.to_u32(h)), Http.octs.len(t)),
            Http.octs.width(Char.to_u32(h))))},
          SCon{h, Http.octs.take(t, Http.octs.len(t))},
          SCon{h, t},
          Equal.cong(Nat, String, m => SCon{h, Http.octs.take(t, m)},
            Nat.sub(Nat.add(Http.octs.width(Char.to_u32(h)), Http.octs.len(t)),
              Http.octs.width(Char.to_u32(h))),
            Http.octs.len(t),
            sub_add(Http.octs.width(Char.to_u32(h)), Http.octs.len(t))),
          Equal.cong(String, String, x => SCon{h, x},
            Http.octs.take(t, Http.octs.len(t)), t, take_all(t))))

def Laws.clen_exact(st, hs, body):
  Equal.trans(Http.Reply,
    Http.parse.clen(st, hs, Http.octs.len(body), body),
    Http.parse.short(st, hs, Http.octs.len(body), body, False{}),
    Http.Reply{st, hs, body},
    Equal.cong(Bool, Http.Reply,
      b => Http.parse.short(st, hs, Http.octs.len(body), body, b),
      Nat.is_lt(Http.octs.len(body), Http.octs.len(body)), False{},
      lt_self(Http.octs.len(body))),
    Equal.cong(String, Http.Reply, x => Http.Reply{st, hs, x},
      Http.octs.take(body, Http.octs.len(body)), body, take_all(body)))

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
    " " ++ path ++ " HTTP/1.1\r\n"
      ++ Http.headers.lines(Http.request.fields(host, hs, body))
      ++ "\r\n" ++ body)

def Laws.get_req_names_path(host, path, hs):
  eq.starts_append(path,
    " HTTP/1.1\r\n" ++ Http.headers.lines(Http.request.fields(host, hs, ""))
      ++ "\r\n")

def Laws.head_req_names_path(host, path, hs):
  eq.starts_append(path,
    " HTTP/1.1\r\n" ++ Http.headers.lines(Http.request.fields(host, hs, ""))
      ++ "\r\n")

def Laws.post_req_names_path(host, path, hs, body):
  +payload = body
  eq.starts_append(path,
    " HTTP/1.1\r\n"
      ++ Http.headers.lines(Http.request.fields(host, hs, payload))
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
    Http.ask.clen(method, target, hs, Http.octs.len(body), body),
    Http.ask.short(method, target, hs, Http.octs.len(body), body, False{}),
    Http.Request{method, target, hs, body},
    Equal.cong(Bool, Http.Request,
      b => Http.ask.short(method, target, hs, Http.octs.len(body), body, b),
      Nat.is_lt(Http.octs.len(body), Http.octs.len(body)), False{},
      lt_self(Http.octs.len(body))),
    Equal.cong(String, Http.Request,
      x => Http.Request{method, target, hs, x},
      Http.octs.take(body, Http.octs.len(body)), body, take_all(body)))

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

def Laws.respond_writes_reason_and_close(_status, _hs, _body):
  {==}

def Laws.put_req_names_path(host, path, hs, body):
  +payload = body
  eq.starts_append(path,
    " HTTP/1.1\r\n"
      ++ Http.headers.lines(Http.request.fields(host, hs, payload))
      ++ "\r\n" ++ payload)

def Laws.delete_req_names_path(host, path, hs, body):
  +payload = body
  eq.starts_append(path,
    " HTTP/1.1\r\n"
      ++ Http.headers.lines(Http.request.fields(host, hs, payload))
      ++ "\r\n" ++ payload)

def Laws.options_req_names_path(host, path, hs):
  eq.starts_append(path,
    " HTTP/1.1\r\n" ++ Http.headers.lines(Http.request.fields(host, hs, ""))
      ++ "\r\n")

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

# --- the request's header fields (SPEC.md HTTP-CLI-8) ---

# a string prefix both sides share does not change starts_with
def eq.starts_cancel(+a: String, +x: String, +y: String)
  -> {String.starts_with.go(String.append(a, y), String.append(a, x))
    == String.starts_with.go(y, x) : Bool}:
  match a:
    case SNil{}:
      {==}
    case SCon{h, t}:
      %Equal.sym(Bool, Char.is_eq(h, h), True{}, eq.char_eq_self(h))
        : {String.starts_with.go.if(String.append(t, y), String.append(t, x), _)
          == String.starts_with.go(y, x) : Bool}
      eq.starts_cancel(t, x, y)

def Laws.exchange_method(_method, _scheme, _host, _port, _path, _hs, _body):
  {==}

def Laws.request_line(method, secure, host, port, path, hs, body):
  +rest = Http.headers.lines(
    Http.request.fields(Http.authority(secure, host, port), hs, body))
    ++ "\r\n" ++ body
  Equal.trans(Bool,
    String.starts_with.go(method ++ " " ++ path ++ " HTTP/1.1\r\n",
      method ++ " " ++ path ++ " HTTP/1.1\r\n" ++ rest),
    String.starts_with.go(" " ++ path ++ " HTTP/1.1\r\n",
      " " ++ path ++ " HTTP/1.1\r\n" ++ rest),
    True{},
    eq.starts_cancel(method, " " ++ path ++ " HTTP/1.1\r\n" ++ rest,
      " " ++ path ++ " HTTP/1.1\r\n"),
    eq.starts_cancel(path, " HTTP/1.1\r\n" ++ rest, " HTTP/1.1\r\n"))

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

# two fields field.same calls the same are the same
def hd.same_sound(+a: Http.Field, +b: Http.Field,
  +e: {True{} == Http.field.same(a, b) : Bool}) -> {a == b : Http.Field}:
  match a:
    case Http.FHost{}:
      match b:
        case Http.FHost{}:
          {==}
        case Http.FAgent{}:
          eq.bit.absurd(&2, {Http.FHost{} == Http.FAgent{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FAccept{}:
          eq.bit.absurd(&2, {Http.FHost{} == Http.FAccept{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FConn{}:
          eq.bit.absurd(&2, {Http.FHost{} == Http.FConn{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FClen{}:
          eq.bit.absurd(&2, {Http.FHost{} == Http.FClen{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FOther{}:
          eq.bit.absurd(&2, {Http.FHost{} == Http.FOther{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
    case Http.FAgent{}:
      match b:
        case Http.FHost{}:
          eq.bit.absurd(&2, {Http.FAgent{} == Http.FHost{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FAgent{}:
          {==}
        case Http.FAccept{}:
          eq.bit.absurd(&2, {Http.FAgent{} == Http.FAccept{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FConn{}:
          eq.bit.absurd(&2, {Http.FAgent{} == Http.FConn{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FClen{}:
          eq.bit.absurd(&2, {Http.FAgent{} == Http.FClen{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FOther{}:
          eq.bit.absurd(&2, {Http.FAgent{} == Http.FOther{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
    case Http.FAccept{}:
      match b:
        case Http.FHost{}:
          eq.bit.absurd(&2, {Http.FAccept{} == Http.FHost{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FAgent{}:
          eq.bit.absurd(&2, {Http.FAccept{} == Http.FAgent{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FAccept{}:
          {==}
        case Http.FConn{}:
          eq.bit.absurd(&2, {Http.FAccept{} == Http.FConn{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FClen{}:
          eq.bit.absurd(&2, {Http.FAccept{} == Http.FClen{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FOther{}:
          eq.bit.absurd(&2, {Http.FAccept{} == Http.FOther{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
    case Http.FConn{}:
      match b:
        case Http.FHost{}:
          eq.bit.absurd(&2, {Http.FConn{} == Http.FHost{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FAgent{}:
          eq.bit.absurd(&2, {Http.FConn{} == Http.FAgent{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FAccept{}:
          eq.bit.absurd(&2, {Http.FConn{} == Http.FAccept{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FConn{}:
          {==}
        case Http.FClen{}:
          eq.bit.absurd(&2, {Http.FConn{} == Http.FClen{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FOther{}:
          eq.bit.absurd(&2, {Http.FConn{} == Http.FOther{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
    case Http.FClen{}:
      match b:
        case Http.FHost{}:
          eq.bit.absurd(&2, {Http.FClen{} == Http.FHost{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FAgent{}:
          eq.bit.absurd(&2, {Http.FClen{} == Http.FAgent{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FAccept{}:
          eq.bit.absurd(&2, {Http.FClen{} == Http.FAccept{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FConn{}:
          eq.bit.absurd(&2, {Http.FClen{} == Http.FConn{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FClen{}:
          {==}
        case Http.FOther{}:
          eq.bit.absurd(&2, {Http.FClen{} == Http.FOther{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
    case Http.FOther{}:
      match b:
        case Http.FHost{}:
          eq.bit.absurd(&2, {Http.FOther{} == Http.FHost{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FAgent{}:
          eq.bit.absurd(&2, {Http.FOther{} == Http.FAgent{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FAccept{}:
          eq.bit.absurd(&2, {Http.FOther{} == Http.FAccept{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FConn{}:
          eq.bit.absurd(&2, {Http.FOther{} == Http.FConn{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FClen{}:
          eq.bit.absurd(&2, {Http.FOther{} == Http.FClen{} : Http.Field},
            Equal.sym(Bool, True{}, False{}, e))
        case Http.FOther{}:
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

def Laws.fields_host_caller(host, hs, body, h, t, e):
  Equal.trans(List<&2, Http.Header>,
    Http.fields.of(Http.FHost{}, Http.request.fields(host, hs, body)),
    List.append(&2, Http.Header, h <> t, []), h <> t,
    hd.of_fields(Http.FHost{},
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
      hd.or_gone(Http.FHost{}, Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}],
      hd.disj(Http.FHost{}, Http.FAgent{}, {==}, hs), {==}),
      hd.or_gone(Http.FHost{}, Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}],
      hd.disj(Http.FHost{}, Http.FAccept{}, {==}, hs), {==}),
      Equal.sym(List<&2, Http.Header>,
        Http.fields.of(Http.FHost{}, Http.fields.of(Http.FOther{}, hs)), [],
      hd.disj(Http.FHost{}, Http.FOther{}, {==}, hs)),
      hd.clen_gone(Http.FHost{}, {==}, Http.utf8.len(body),
      Nat.is_eq(Http.utf8.len(body), 0n))),
    hd.app_nil(h <> t))

def Laws.fields_host_dflt(host, hs, body, e):
  hd.of_fields(Http.FHost{},
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
      hd.or_gone(Http.FHost{}, Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}],
      hd.disj(Http.FHost{}, Http.FAgent{}, {==}, hs), {==}),
      hd.or_gone(Http.FHost{}, Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}],
      hd.disj(Http.FHost{}, Http.FAccept{}, {==}, hs), {==}),
      Equal.sym(List<&2, Http.Header>,
        Http.fields.of(Http.FHost{}, Http.fields.of(Http.FOther{}, hs)), [],
      hd.disj(Http.FHost{}, Http.FOther{}, {==}, hs)),
      hd.clen_gone(Http.FHost{}, {==}, Http.utf8.len(body),
      Nat.is_eq(Http.utf8.len(body), 0n)))

def Laws.fields_agent_caller(host, hs, body, h, t, e):
  Equal.trans(List<&2, Http.Header>,
    Http.fields.of(Http.FAgent{}, Http.request.fields(host, hs, body)),
    List.append(&2, Http.Header, h <> t, []), h <> t,
    hd.of_fields(Http.FAgent{},
      Http.fields.or(Http.fields.of(Http.FHost{}, hs), [Http.H{"Host", host}]),
      Http.fields.or(Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}]),
      Http.fields.or(Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}]),
      Http.fields.of(Http.FOther{}, hs),
      Http.clen.field(Http.utf8.len(body), Nat.is_eq(Http.utf8.len(body), 0n)),
      [], h <> t, [], [], [],
      hd.or_gone(Http.FAgent{}, Http.fields.of(Http.FHost{}, hs),
        [Http.H{"Host", host}],
      hd.disj(Http.FAgent{}, Http.FHost{}, {==}, hs), {==}),
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
      hd.or_gone(Http.FAgent{}, Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}],
      hd.disj(Http.FAgent{}, Http.FAccept{}, {==}, hs), {==}),
      Equal.sym(List<&2, Http.Header>,
        Http.fields.of(Http.FAgent{}, Http.fields.of(Http.FOther{}, hs)), [],
      hd.disj(Http.FAgent{}, Http.FOther{}, {==}, hs)),
      hd.clen_gone(Http.FAgent{}, {==}, Http.utf8.len(body),
      Nat.is_eq(Http.utf8.len(body), 0n))),
    hd.app_nil(h <> t))

def Laws.fields_agent_dflt(host, hs, body, e):
  hd.of_fields(Http.FAgent{},
      Http.fields.or(Http.fields.of(Http.FHost{}, hs), [Http.H{"Host", host}]),
      Http.fields.or(Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}]),
      Http.fields.or(Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}]),
      Http.fields.of(Http.FOther{}, hs),
      Http.clen.field(Http.utf8.len(body), Nat.is_eq(Http.utf8.len(body), 0n)),
      [], [Http.H{"User-Agent", "ezhttp"}], [], [], [],
      hd.or_gone(Http.FAgent{}, Http.fields.of(Http.FHost{}, hs),
        [Http.H{"Host", host}],
      hd.disj(Http.FAgent{}, Http.FHost{}, {==}, hs), {==}),
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
      hd.or_gone(Http.FAgent{}, Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}],
      hd.disj(Http.FAgent{}, Http.FAccept{}, {==}, hs), {==}),
      Equal.sym(List<&2, Http.Header>,
        Http.fields.of(Http.FAgent{}, Http.fields.of(Http.FOther{}, hs)), [],
      hd.disj(Http.FAgent{}, Http.FOther{}, {==}, hs)),
      hd.clen_gone(Http.FAgent{}, {==}, Http.utf8.len(body),
      Nat.is_eq(Http.utf8.len(body), 0n)))

def Laws.fields_accept_caller(host, hs, body, h, t, e):
  Equal.trans(List<&2, Http.Header>,
    Http.fields.of(Http.FAccept{}, Http.request.fields(host, hs, body)),
    List.append(&2, Http.Header, h <> t, []), h <> t,
    hd.of_fields(Http.FAccept{},
      Http.fields.or(Http.fields.of(Http.FHost{}, hs), [Http.H{"Host", host}]),
      Http.fields.or(Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}]),
      Http.fields.or(Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}]),
      Http.fields.of(Http.FOther{}, hs),
      Http.clen.field(Http.utf8.len(body), Nat.is_eq(Http.utf8.len(body), 0n)),
      [], [], h <> t, [], [],
      hd.or_gone(Http.FAccept{}, Http.fields.of(Http.FHost{}, hs),
        [Http.H{"Host", host}],
      hd.disj(Http.FAccept{}, Http.FHost{}, {==}, hs), {==}),
      hd.or_gone(Http.FAccept{}, Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}],
      hd.disj(Http.FAccept{}, Http.FAgent{}, {==}, hs), {==}),
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
      hd.disj(Http.FAccept{}, Http.FOther{}, {==}, hs)),
      hd.clen_gone(Http.FAccept{}, {==}, Http.utf8.len(body),
      Nat.is_eq(Http.utf8.len(body), 0n))),
    hd.app_nil(h <> t))

def Laws.fields_accept_dflt(host, hs, body, e):
  hd.of_fields(Http.FAccept{},
      Http.fields.or(Http.fields.of(Http.FHost{}, hs), [Http.H{"Host", host}]),
      Http.fields.or(Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}]),
      Http.fields.or(Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}]),
      Http.fields.of(Http.FOther{}, hs),
      Http.clen.field(Http.utf8.len(body), Nat.is_eq(Http.utf8.len(body), 0n)),
      [], [], [Http.H{"Accept", "*/*"}], [], [],
      hd.or_gone(Http.FAccept{}, Http.fields.of(Http.FHost{}, hs),
        [Http.H{"Host", host}],
      hd.disj(Http.FAccept{}, Http.FHost{}, {==}, hs), {==}),
      hd.or_gone(Http.FAccept{}, Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}],
      hd.disj(Http.FAccept{}, Http.FAgent{}, {==}, hs), {==}),
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
      hd.disj(Http.FAccept{}, Http.FOther{}, {==}, hs)),
      hd.clen_gone(Http.FAccept{}, {==}, Http.utf8.len(body),
      Nat.is_eq(Http.utf8.len(body), 0n)))

def Laws.fields_conn(host, hs, body):
  hd.of_fields(Http.FConn{},
      Http.fields.or(Http.fields.of(Http.FHost{}, hs), [Http.H{"Host", host}]),
      Http.fields.or(Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}]),
      Http.fields.or(Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}]),
      Http.fields.of(Http.FOther{}, hs),
      Http.clen.field(Http.utf8.len(body), Nat.is_eq(Http.utf8.len(body), 0n)),
      [], [], [], [], [],
      hd.or_gone(Http.FConn{}, Http.fields.of(Http.FHost{}, hs),
        [Http.H{"Host", host}],
      hd.disj(Http.FConn{}, Http.FHost{}, {==}, hs), {==}),
      hd.or_gone(Http.FConn{}, Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}],
      hd.disj(Http.FConn{}, Http.FAgent{}, {==}, hs), {==}),
      hd.or_gone(Http.FConn{}, Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}],
      hd.disj(Http.FConn{}, Http.FAccept{}, {==}, hs), {==}),
      Equal.sym(List<&2, Http.Header>,
        Http.fields.of(Http.FConn{}, Http.fields.of(Http.FOther{}, hs)), [],
      hd.disj(Http.FConn{}, Http.FOther{}, {==}, hs)),
      hd.clen_gone(Http.FConn{}, {==}, Http.utf8.len(body),
      Nat.is_eq(Http.utf8.len(body), 0n)))

def Laws.fields_clen(host, hs, body):
  hd.of_fields(Http.FClen{},
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
      hd.or_gone(Http.FClen{}, Http.fields.of(Http.FHost{}, hs),
        [Http.H{"Host", host}],
      hd.disj(Http.FClen{}, Http.FHost{}, {==}, hs), {==}),
      hd.or_gone(Http.FClen{}, Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}],
      hd.disj(Http.FClen{}, Http.FAgent{}, {==}, hs), {==}),
      hd.or_gone(Http.FClen{}, Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}],
      hd.disj(Http.FClen{}, Http.FAccept{}, {==}, hs), {==}),
      Equal.sym(List<&2, Http.Header>,
        Http.fields.of(Http.FClen{}, Http.fields.of(Http.FOther{}, hs)), [],
      hd.disj(Http.FClen{}, Http.FOther{}, {==}, hs)),
      hd.clen_self(Http.utf8.len(body), Nat.is_eq(Http.utf8.len(body), 0n)))

def Laws.fields_other(host, hs, body):
  Equal.trans(List<&2, Http.Header>,
    Http.fields.of(Http.FOther{}, Http.request.fields(host, hs, body)),
    List.append(&2, Http.Header, Http.fields.of(Http.FOther{}, hs), []),
      Http.fields.of(Http.FOther{}, hs),
    hd.of_fields(Http.FOther{},
      Http.fields.or(Http.fields.of(Http.FHost{}, hs), [Http.H{"Host", host}]),
      Http.fields.or(Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}]),
      Http.fields.or(Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}]),
      Http.fields.of(Http.FOther{}, hs),
      Http.clen.field(Http.utf8.len(body), Nat.is_eq(Http.utf8.len(body), 0n)),
      [], [], [], Http.fields.of(Http.FOther{}, hs), [],
      hd.or_gone(Http.FOther{}, Http.fields.of(Http.FHost{}, hs),
        [Http.H{"Host", host}],
      hd.disj(Http.FOther{}, Http.FHost{}, {==}, hs), {==}),
      hd.or_gone(Http.FOther{}, Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}],
      hd.disj(Http.FOther{}, Http.FAgent{}, {==}, hs), {==}),
      hd.or_gone(Http.FOther{}, Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}],
      hd.disj(Http.FOther{}, Http.FAccept{}, {==}, hs), {==}),
      Equal.sym(List<&2, Http.Header>,
        Http.fields.of(Http.FOther{}, Http.fields.of(Http.FOther{}, hs)),
        Http.fields.of(Http.FOther{}, hs),
        hd.idem(Http.FOther{}, hs)),
      hd.clen_gone(Http.FOther{}, {==}, Http.utf8.len(body),
      Nat.is_eq(Http.utf8.len(body), 0n))),
    hd.app_nil(Http.fields.of(Http.FOther{}, hs)))

def Laws.follows_get(follow):
  match follow:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.follows_other(_method, e, follow):
  match follow:
    case True{}:
      %e : {_ == False{} : Bool}
      {==}
    case False{}:
      {==}

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

def Laws.whole_open(_f, _asked):
  {==}

def Laws.whole_head(f, asked, before, after, e):
  %e : {Http.whole.step(asked, String.lines(before), after, _,
    cut => Http.whole.go(f, asked, cut))
    == Http.whole.of(Http.frame(Bool.or(asked, Http.status.bare(Http.status.of(String.lines(before)))),
      Http.head.go(String.lines(before), "transfer-encoding"),
      Http.head.values(String.lines(before), "content-length")), after) : Bool}
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

# --- counting octets without walking all of them (utf8.has) ---

law lt_over:
  for k: Nat
  for w: Nat
  for +l: Nat
  for e: {True{} == Nat.is_lt(k, w) : Bool}
  {Nat.is_lt(Nat.add(w, l), k) == False{} : Bool}

def lt_over(k, w, l, e):
  match k w:
    case 0n 0n:
      eq.bit.absurd(&2, {Nat.is_lt(Nat.add(0n, l), 0n) == False{} : Bool},
        Equal.sym(Bool, True{}, False{}, e))
    case 0n 1n+p:
      {==}
    case 1n+q 0n:
      eq.bit.absurd(&2, {Nat.is_lt(Nat.add(0n, l), 1n+q) == False{} : Bool},
        Equal.sym(Bool, True{}, False{}, e))
    case 1n+q 1n+p:
      lt_over(q, p, l, e)

law lt_shift:
  for k: Nat
  for w: Nat
  for +l: Nat
  for e: {False{} == Nat.is_lt(k, w) : Bool}
  {Nat.is_lt(Nat.add(w, l), k) == Nat.is_lt(l, Nat.sub(k, w)) : Bool}

def lt_shift(k, w, l, e):
  match k w:
    case 0n 0n:
      {==}
    case 1n+q 0n:
      {==}
    case 0n 1n+p:
      eq.bit.absurd(&2, {Nat.is_lt(Nat.add(1n+p, l), 0n)
        == Nat.is_lt(l, Nat.sub(0n, 1n+p)) : Bool}, e)
    case 1n+q 1n+p:
      lt_shift(q, p, l, e)

law has_len.arm:
  for n: Nat
  for w: Nat
  for +l: Nat
  for r: Bool
  for b: Bool
  for e: {b == Nat.is_lt(n, w) : Bool}
  for ih: {r == Bool.not(Nat.is_lt(l, Nat.sub(n, w))) : Bool}
  {Http.octs.has.step(b, _u => r) == Bool.not(Nat.is_lt(Nat.add(w, l), n))
    : Bool}

def has_len.arm(n, w, l, r, b, e, ih):
  match b:
    case True{}:
      Equal.cong(Bool, Bool, x => Bool.not(x), False{},
        Nat.is_lt(Nat.add(w, l), n),
        Equal.sym(Bool, Nat.is_lt(Nat.add(w, l), n), False{},
          lt_over(n, w, l, e)))
    case False{}:
      Equal.trans(Bool, r, Bool.not(Nat.is_lt(l, Nat.sub(n, w))),
        Bool.not(Nat.is_lt(Nat.add(w, l), n)), ih,
        Equal.cong(Bool, Bool, x => Bool.not(x),
          Nat.is_lt(l, Nat.sub(n, w)), Nat.is_lt(Nat.add(w, l), n),
          Equal.sym(Bool, Nat.is_lt(Nat.add(w, l), n),
            Nat.is_lt(l, Nat.sub(n, w)), lt_shift(n, w, l, e))))

law has_len:
  for s: String
  for +n: Nat
  {Http.octs.has(s, n) == Bool.not(Nat.is_lt(Http.octs.len(s), n)) : Bool}

def has_len(s, n):
  match s:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      +w = Http.octs.width(Char.to_u32(h))
      has_len.arm(n, w, Http.octs.len(t), Http.octs.has(t, Nat.sub(n, w)),
        Nat.is_lt(n, w), {==}, has_len(t, Nat.sub(n, w)))

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
    cut => Http.chunks.ended(f, cut)) == Http.chunks.ended(f, Http.divide(Http.octs.drop(after,
      Nat.add(Http.hexlen(before), 2n)), "\r\n")) : Bool}
  %e2 : {Http.chunks.ended.size(after, Http.hexlen(before), _,
    cut => Http.chunks.ended(f, cut)) == Http.chunks.ended(f, Http.divide(Http.octs.drop(after,
      Nat.add(Http.hexlen(before), 2n)), "\r\n")) : Bool}
  %e3 : {Http.chunks.ended.data(after, Http.hexlen(before), _,
    cut => Http.chunks.ended(f, cut)) == Http.chunks.ended(f, Http.divide(Http.octs.drop(after,
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

def Laws.chunk_ready(after, n):
  Equal.cong(Bool, Bool,
    x => Bool.and(x, String.starts_with(Http.octs.drop(after, n), "\r\n")),
    Http.octs.has(after, Nat.add(n, 2n)),
    Bool.not(Nat.is_lt(Http.octs.len(after), Nat.add(n, 2n))),
    has_len(after, Nat.add(n, 2n)))

def eq.drop_zero(s: String) -> {String.drop(s, 0n) == s : String}:
  match s:
    case SNil{}:
      {==}
    case SCon{h, t}:
      {==}

# --- the chunk walk, read by read (SPEC.md HTTP-CLI-12) ---

# what a skip leaves: the text after the octets it walked off
def sk.text(s: Http.Skip) -> String:
  match s:
    case Http.Short{o}:
      ""
    case Http.Over{l, r}:
      r

# whether a text is at least the skipped octets and j more
def sk.has(s: Http.Skip, +j: Nat) -> Bool:
  match s:
    case Http.Short{o}:
      Http.octs.has("", Nat.add(o, j))
    case Http.Over{l, r}:
      Http.octs.has(r, Nat.add(l, j))

# the text after the skipped octets and j more
def sk.drop(s: Http.Skip, +j: Nat) -> String:
  match s:
    case Http.Short{o}:
      ""
    case Http.Over{l, r}:
      Http.octs.drop(r, Nat.add(l, j))

# a skip carried on into more text
def sk.then(s: Http.Skip, b: String) -> Http.Skip:
  match s:
    case Http.Short{o}:
      Http.octs.skip(b, o)
    case Http.Over{l, r}:
      Http.Over{l, r ++ b}

law width_pos:
  for +u: U32
  {Nat.is_lt(0n, Http.octs.width(u)) == True{} : Bool}

def width_pos(_u):
  {==}

law has_zero:
  for s: String
  {Http.octs.has(s, 0n) == True{} : Bool}

def has_zero(s):
  match s:
    case SNil{}:
      {==}
    case SCon{+h, t}:
      +w = Http.octs.width(Char.to_u32(h))
      %Equal.sym(Bool, Nat.is_lt(0n, w), True{}, width_pos(Char.to_u32(h)))
        : {Http.octs.has.step(_, _u => Http.octs.has(t, Nat.sub(0n, w)))
          == True{} : Bool}
      {==}

law drop_zero8:
  for s: String
  {Http.octs.drop(s, 0n) == s : String}

def drop_zero8(s):
  match s:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      +w = Http.octs.width(Char.to_u32(h))
      %Equal.sym(Bool, Nat.is_lt(0n, w), True{}, width_pos(Char.to_u32(h)))
        : {Http.octs.drop.step(_, h, t, _u => Http.octs.drop(t, Nat.sub(0n, w)))
          == SCon{h, t} : String}
      {==}

law lt_grow:
  for n: Nat
  for w: Nat
  for +j: Nat
  for e: {False{} == Nat.is_lt(n, w) : Bool}
  {Nat.is_lt(Nat.add(n, j), w) == False{} : Bool}

def lt_grow(n, w, j, e):
  match n w:
    case 0n 0n:
      lt_zero(j)
    case 1n+q 0n:
      {==}
    case 0n 1n+p:
      eq.bit.absurd(&2, {Nat.is_lt(Nat.add(0n, j), 1n+p) == False{} : Bool}, e)
    case 1n+q 1n+p:
      lt_grow(q, p, j, e)

law sub_grow:
  for n: Nat
  for w: Nat
  for +j: Nat
  for e: {False{} == Nat.is_lt(n, w) : Bool}
  {Nat.sub(Nat.add(n, j), w) == Nat.add(Nat.sub(n, w), j) : Nat}

def sub_grow(n, w, j, e):
  match n w:
    case 0n 0n:
      sub_zero(j)
    case 1n+q 0n:
      {==}
    case 0n 1n+p:
      eq.bit.absurd(&2, {Nat.sub(Nat.add(0n, j), 1n+p)
        == Nat.add(Nat.sub(0n, 1n+p), j) : Nat}, e)
    case 1n+q 1n+p:
      sub_grow(q, p, j, e)

law skip_text.arm:
  for -h: Char
  for -t: String
  for -n: Nat
  for -w: Nat
  for b: Bool
  for ih: {Http.octs.drop(t, Nat.sub(n, w))
    == sk.text(Http.octs.skip(t, Nat.sub(n, w))) : String}
  {Http.octs.drop.step(b, h, t, _u => Http.octs.drop(t, Nat.sub(n, w)))
    == sk.text(Http.octs.skip.step(b, n, h, t,
      _u => Http.octs.skip(t, Nat.sub(n, w)))) : String}

def skip_text.arm(_h, _t, _n, _w, b, ih):
  match b:
    case True{}:
      {==}
    case False{}:
      ih

law skip_text:
  for s: String
  for +n: Nat
  {Http.octs.drop(s, n) == sk.text(Http.octs.skip(s, n)) : String}

def skip_text(s, n):
  match s:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      +w = Http.octs.width(Char.to_u32(h))
      skip_text.arm(h, t, n, w, Nat.is_lt(n, w), skip_text(t, Nat.sub(n, w)))

law skip_has.arm:
  for +h: Char
  for +t: String
  for +n: Nat
  for +j: Nat
  for b: Bool
  for +e: {b == Nat.is_lt(n, Http.octs.width(Char.to_u32(h))) : Bool}
  for ih: {Http.octs.has(t, Nat.add(Nat.sub(n, Http.octs.width(Char.to_u32(h))), j))
    == sk.has(Http.octs.skip(t, Nat.sub(n, Http.octs.width(Char.to_u32(h)))), j) : Bool}
  {Http.octs.has(SCon{h, t}, Nat.add(n, j))
    == sk.has(Http.octs.skip.step(b, n, h, t,
      _u => Http.octs.skip(t, Nat.sub(n, Http.octs.width(Char.to_u32(h))))), j) : Bool}

def skip_has.arm(h, t, n, j, b, e, ih):
  match b:
    case True{}:
      {==}
    case False{}:
      %Equal.sym(Bool, Nat.is_lt(Nat.add(n, j), Http.octs.width(Char.to_u32(h))), False{}, lt_grow(n,
          Http.octs.width(Char.to_u32(h)), j, e))
        : {Http.octs.has.step(_,
          _u => Http.octs.has(t, Nat.sub(Nat.add(n, j), Http.octs.width(Char.to_u32(h)))))
          == sk.has(Http.octs.skip(t, Nat.sub(n, Http.octs.width(Char.to_u32(h)))), j) : Bool}
      %Equal.sym(Nat, Nat.sub(Nat.add(n, j), Http.octs.width(Char.to_u32(h))), Nat.add(Nat.sub(n,
          Http.octs.width(Char.to_u32(h))), j),
        sub_grow(n, Http.octs.width(Char.to_u32(h)), j, e))
        : {Http.octs.has(t, _)
          == sk.has(Http.octs.skip(t, Nat.sub(n, Http.octs.width(Char.to_u32(h)))), j) : Bool}
      ih

law skip_has:
  for s: String
  for +n: Nat
  for +j: Nat
  {Http.octs.has(s, Nat.add(n, j)) == sk.has(Http.octs.skip(s, n), j) : Bool}

def skip_has(s, n, j):
  match s:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      skip_has.arm(h, t, n, j, Nat.is_lt(n, Http.octs.width(Char.to_u32(h))), {==},
        skip_has(t, Nat.sub(n, Http.octs.width(Char.to_u32(h))), j))

law skip_drop.arm:
  for +h: Char
  for +t: String
  for +n: Nat
  for +j: Nat
  for b: Bool
  for +e: {b == Nat.is_lt(n, Http.octs.width(Char.to_u32(h))) : Bool}
  for ih: {Http.octs.drop(t, Nat.add(Nat.sub(n, Http.octs.width(Char.to_u32(h))), j))
    == sk.drop(Http.octs.skip(t, Nat.sub(n, Http.octs.width(Char.to_u32(h)))), j) : String}
  {Http.octs.drop(SCon{h, t}, Nat.add(n, j))
    == sk.drop(Http.octs.skip.step(b, n, h, t,
      _u => Http.octs.skip(t, Nat.sub(n, Http.octs.width(Char.to_u32(h))))), j) : String}

def skip_drop.arm(h, t, n, j, b, e, ih):
  match b:
    case True{}:
      {==}
    case False{}:
      %Equal.sym(Bool, Nat.is_lt(Nat.add(n, j), Http.octs.width(Char.to_u32(h))), False{}, lt_grow(n,
          Http.octs.width(Char.to_u32(h)), j, e))
        : {Http.octs.drop.step(_, h, t,
          _u => Http.octs.drop(t, Nat.sub(Nat.add(n, j), Http.octs.width(Char.to_u32(h)))))
          == sk.drop(Http.octs.skip(t, Nat.sub(n, Http.octs.width(Char.to_u32(h)))), j) : String}
      %Equal.sym(Nat, Nat.sub(Nat.add(n, j), Http.octs.width(Char.to_u32(h))), Nat.add(Nat.sub(n,
          Http.octs.width(Char.to_u32(h))), j),
        sub_grow(n, Http.octs.width(Char.to_u32(h)), j, e))
        : {Http.octs.drop(t, _)
          == sk.drop(Http.octs.skip(t, Nat.sub(n, Http.octs.width(Char.to_u32(h)))), j) : String}
      ih

law skip_drop:
  for s: String
  for +n: Nat
  for +j: Nat
  {Http.octs.drop(s, Nat.add(n, j)) == sk.drop(Http.octs.skip(s, n), j)
    : String}

def skip_drop(s, n, j):
  match s:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      skip_drop.arm(h, t, n, j, Nat.is_lt(n, Http.octs.width(Char.to_u32(h))), {==},
        skip_drop(t, Nat.sub(n, Http.octs.width(Char.to_u32(h))), j))

law skip_app.arm:
  for +h: Char
  for +t: String
  for +b: String
  for +n: Nat
  for c: Bool
  for ih: {Http.octs.skip(t ++ b, Nat.sub(n, Http.octs.width(Char.to_u32(h))))
    == sk.then(Http.octs.skip(t, Nat.sub(n, Http.octs.width(Char.to_u32(h)))), b) : Http.Skip}
  {Http.octs.skip.step(c, n, h, t ++ b,
    _u => Http.octs.skip(t ++ b, Nat.sub(n, Http.octs.width(Char.to_u32(h)))))
    == sk.then(Http.octs.skip.step(c, n, h, t,
      _u => Http.octs.skip(t, Nat.sub(n, Http.octs.width(Char.to_u32(h))))), b) : Http.Skip}

def skip_app.arm(_h, _t, _b, _n, c, ih):
  match c:
    case True{}:
      {==}
    case False{}:
      ih

law skip_app:
  for s: String
  for +b: String
  for +n: Nat
  {Http.octs.skip(s ++ b, n) == sk.then(Http.octs.skip(s, n), b) : Http.Skip}

def skip_app(s, b, n):
  match s:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      skip_app.arm(h, t, b, n, Nat.is_lt(n, Http.octs.width(Char.to_u32(h))), skip_app(t, b, Nat.sub(n,
          Http.octs.width(Char.to_u32(h)))))

law has_app.arm:
  for +h: Char
  for +t: String
  for +b: String
  for +k: Nat
  for c: Bool
  for e: {True{} == Http.octs.has.step(c, _u => Http.octs.has(t, Nat.sub(k, Http.octs.width(Char.to_u32(h)))))
    : Bool}
  for ih: @e2: {True{} == Http.octs.has(t, Nat.sub(k, Http.octs.width(Char.to_u32(h)))) : Bool} ->
    {Http.octs.has(t ++ b, Nat.sub(k, Http.octs.width(Char.to_u32(h)))) == True{} : Bool}
  {Http.octs.has.step(c, _u => Http.octs.has(t ++ b, Nat.sub(k, Http.octs.width(Char.to_u32(h)))))
    == True{} : Bool}

def has_app.arm(_h, _t, _b, _k, c, e, ih):
  match c:
    case True{}:
      {==}
    case False{}:
      ih(e)

law has_app:
  for s: String
  for +b: String
  for +k: Nat
  for e: {True{} == Http.octs.has(s, k) : Bool}
  {Http.octs.has(s ++ b, k) == True{} : Bool}

def has_app(s, b, k, e):
  match s k:
    case SNil{} 0n:
      has_zero(b)
    case SNil{} 1n+p:
      eq.bit.absurd(&2, {Http.octs.has(b, 1n+p) == True{} : Bool},
        Equal.sym(Bool, True{}, False{}, e))
    case SCon{+h, +t} _:
      has_app.arm(h, t, b, k, Nat.is_lt(k, Http.octs.width(Char.to_u32(h))), e,
        e2 => has_app(t, b, Nat.sub(k, Http.octs.width(Char.to_u32(h))), e2))

law drop_app.arm:
  for +h: Char
  for +t: String
  for +b: String
  for +k: Nat
  for c: Bool
  for e: {True{} == Http.octs.has.step(c, _u => Http.octs.has(t, Nat.sub(k, Http.octs.width(Char.to_u32(h)))))
    : Bool}
  for ih: @e2: {True{} == Http.octs.has(t, Nat.sub(k, Http.octs.width(Char.to_u32(h)))) : Bool} ->
    {Http.octs.drop(t ++ b, Nat.sub(k, Http.octs.width(Char.to_u32(h)))) == Http.octs.drop(t, Nat.sub(k,
        Http.octs.width(Char.to_u32(h)))) ++ b
      : String}
  {Http.octs.drop.step(c, h, t ++ b, _u => Http.octs.drop(t ++ b, Nat.sub(k, Http.octs.width(Char.to_u32(h)))))
    == Http.octs.drop.step(c, h, t, _u => Http.octs.drop(t, Nat.sub(k, Http.octs.width(Char.to_u32(h))))) ++ b
    : String}

def drop_app.arm(_h, _t, _b, _k, c, e, ih):
  match c:
    case True{}:
      {==}
    case False{}:
      ih(e)

law drop_app:
  for s: String
  for +b: String
  for +k: Nat
  for e: {True{} == Http.octs.has(s, k) : Bool}
  {Http.octs.drop(s ++ b, k) == Http.octs.drop(s, k) ++ b : String}

def drop_app(s, b, k, e):
  match s k:
    case SNil{} 0n:
      drop_zero8(b)
    case SNil{} 1n+p:
      eq.bit.absurd(&2, {Http.octs.drop(b, 1n+p) == b : String},
        Equal.sym(Bool, True{}, False{}, e))
    case SCon{+h, +t} _:
      drop_app.arm(h, t, b, k, Nat.is_lt(k, Http.octs.width(Char.to_u32(h))), e,
        e2 => drop_app(t, b, Nat.sub(k, Http.octs.width(Char.to_u32(h))), e2))

law sw_app.arm:
  for +xt: String
  for +yt: String
  for +b: String
  for c: Bool
  for e: {True{} == String.starts_with.go.if(yt, xt, c) : Bool}
  for ih: @e2: {True{} == String.starts_with.go(yt, xt) : Bool} ->
    {String.starts_with.go(yt, xt ++ b) == True{} : Bool}
  {String.starts_with.go.if(yt, xt ++ b, c) == True{} : Bool}

def sw_app.arm(_xt, _yt, _b, c, e, ih):
  match c:
    case True{}:
      ih(e)
    case False{}:
      eq.bit.absurd(&2, {False{} == True{} : Bool},
        Equal.sym(Bool, True{}, False{}, e))

law sw_app:
  for s: String
  for p: String
  for +b: String
  for e: {True{} == String.starts_with(s, p) : Bool}
  {String.starts_with(s ++ b, p) == True{} : Bool}

def sw_app(s, p, b, e):
  match s p:
    case _ SNil{}:
      {==}
    case SNil{} SCon{y, yt}:
      eq.bit.absurd(&2, {String.starts_with.go(SCon{y, yt}, b) == True{} : Bool},
        Equal.sym(Bool, True{}, False{}, e))
    case SCon{+x, +xt} SCon{+y, +yt}:
      sw_app.arm(xt, yt, b, Char.is_eq(x, y), e, e2 => sw_app(xt, yt, b, e2))

law contains_nil:
  for s: String
  {String.contains(s, "") == True{} : Bool}

def contains_nil(s):
  match s:
    case SNil{}:
      {==}
    case SCon{h, t}:
      {==}

law contains_if:
  for +t: String
  for +p: String
  for c: Bool
  for e: {String.contains(t, p) == True{} : Bool}
  {String.contains.if(t, p, c) == True{} : Bool}

def contains_if(_t, _p, c, e):
  match c:
    case True{}:
      {==}
    case False{}:
      e

law contains_app.arm:
  for +h: Char
  for +t: String
  for +p: String
  for +b: String
  for c: Bool
  for +ec: {c == String.starts_with(SCon{h, t}, p) : Bool}
  for e: {True{} == String.contains.if(t, p, c) : Bool}
  for ih: @e2: {True{} == String.contains(t, p) : Bool} ->
    {String.contains(t ++ b, p) == True{} : Bool}
  {String.contains.if(t ++ b, p, String.starts_with(SCon{h, t ++ b}, p))
    == True{} : Bool}

def contains_app.arm(h, t, p, b, c, ec, e, ih):
  match c:
    case True{}:
      %Equal.sym(Bool, String.starts_with(SCon{h, t} ++ b, p), True{},
        sw_app(SCon{h, t}, p, b, ec))
        : {String.contains.if(t ++ b, p, _) == True{} : Bool}
      {==}
    case False{}:
      contains_if(t ++ b, p, String.starts_with(SCon{h, t ++ b}, p), ih(e))

law contains_app:
  for s: String
  for +p: String
  for +b: String
  for e: {True{} == String.contains(s, p) : Bool}
  {String.contains(s ++ b, p) == True{} : Bool}

def contains_app(s, p, b, e):
  match s p:
    case SNil{} SNil{}:
      contains_nil(b)
    case SNil{} SCon{y, yt}:
      eq.bit.absurd(&2, {String.contains(b, SCon{y, yt}) == True{} : Bool},
        Equal.sym(Bool, True{}, False{}, e))
    case SCon{+h, +t} _:
      contains_app.arm(h, t, p, b, String.starts_with(SCon{h, t}, p), {==}, e,
        e2 => contains_app(t, p, b, e2))

law or_true:
  for x: Bool
  {Bool.or(x, True{}) == True{} : Bool}

def or_true(x):
  match x:
    case True{}:
      {==}
    case False{}:
      {==}

law or_app:
  for x: Bool
  for y: Bool
  for +x2: Bool
  for +y2: Bool
  for e: {True{} == Bool.or(x, y) : Bool}
  for fx: @ex: {True{} == x : Bool} -> {x2 == True{} : Bool}
  for fy: @ey: {True{} == y : Bool} -> {y2 == True{} : Bool}
  {Bool.or(x2, y2) == True{} : Bool}

def or_app(x, _y, x2, y2, e, fx, fy):
  match x:
    case True{}:
      %Equal.sym(Bool, x2, True{}, fx({==})) : {Bool.or(_, y2) == True{} : Bool}
      {==}
    case False{}:
      %Equal.sym(Bool, y2, True{}, fy(e))
        : {Bool.or(x2, _) == True{} : Bool}
      or_true(x2)

law trailer_app:
  for +after: String
  for +b: String
  for e: {True{} == Http.chunks.trailer(after) : Bool}
  {Http.chunks.trailer(after ++ b) == True{} : Bool}

def trailer_app(after, b, e):
  or_app(String.starts_with(after, "\r\n"), String.contains(after, "\r\n\r\n"),
    String.starts_with(after ++ b, "\r\n"),
    String.contains(after ++ b, "\r\n\r\n"), e,
    ex => sw_app(after, "\r\n", b, ex),
    ey => contains_app(after, "\r\n\r\n", b, ey))

# whether a divide found its pattern
def cut.is(c: Http.Cut) -> Bool:
  match c:
    case Http.NoCut{}:
      False{}
    case Http.Cut{x, y}:
      True{}

# a divide's second half with more text after it
def cut.app(c: Http.Cut, b: String) -> Http.Cut:
  match c:
    case Http.NoCut{}:
      Http.NoCut{}
    case Http.Cut{x, y}:
      Http.Cut{x, y ++ b}

law cut_is_push:
  for h: Char
  for r: Http.Cut
  {cut.is(Http.divide.push(h, r)) == cut.is(r) : Bool}

def cut_is_push(_h, r):
  match r:
    case Http.NoCut{}:
      {==}
    case Http.Cut{x, y}:
      {==}

law cut_app_push:
  for h: Char
  for r: Http.Cut
  for +b: String
  {cut.app(Http.divide.push(h, r), b) == Http.divide.push(h, cut.app(r, b))
    : Http.Cut}

def cut_app_push(_h, r, _b):
  match r:
    case Http.NoCut{}:
      {==}
    case Http.Cut{x, y}:
      {==}

law len_app:
  for a: String
  for +b: String
  {String.length(a ++ b) == Nat.add(String.length(a), String.length(b)) : Nat}

def len_app(a, b):
  match a:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      Equal.cong(Nat, Nat, x => 1n+x, String.length(t ++ b),
        Nat.add(String.length(t), String.length(b)), len_app(t, b))

law lt_succ:
  for l: Nat
  for p: Nat
  for e: {False{} == Nat.is_lt(l, p) : Bool}
  {Nat.is_lt(1n+l, p) == False{} : Bool}

def lt_succ(l, p, e):
  match l p:
    case _ 0n:
      {==}
    case 0n 1n+q:
      eq.bit.absurd(&2, {Nat.is_lt(1n, 1n+q) == False{} : Bool}, e)
    case 1n+k 1n+q:
      lt_succ(k, q, e)

law sw_len.arm:
  for +xt: String
  for +yt: String
  for c: Bool
  for e: {True{} == String.starts_with.go.if(yt, xt, c) : Bool}
  for ih: @e2: {True{} == String.starts_with.go(yt, xt) : Bool} ->
    {Nat.is_lt(String.length(xt), String.length(yt)) == False{} : Bool}
  {Nat.is_lt(String.length(xt), String.length(yt)) == False{} : Bool}

def sw_len.arm(xt, yt, c, e, ih):
  match c:
    case True{}:
      ih(e)
    case False{}:
      eq.bit.absurd(&2, {Nat.is_lt(String.length(xt), String.length(yt))
        == False{} : Bool}, Equal.sym(Bool, True{}, False{}, e))

law sw_len:
  for s: String
  for p: String
  for e: {True{} == String.starts_with(s, p) : Bool}
  {Nat.is_lt(String.length(s), String.length(p)) == False{} : Bool}

def sw_len(s, p, e):
  match s p:
    case _ SNil{}:
      lt_zero(String.length(s))
    case SNil{} SCon{y, yt}:
      eq.bit.absurd(&2, {Nat.is_lt(0n, 1n+String.length(yt)) == False{} : Bool},
        Equal.sym(Bool, True{}, False{}, e))
    case SCon{+x, +xt} SCon{+y, +yt}:
      sw_len.arm(xt, yt, Char.is_eq(x, y), e, e2 => sw_len(xt, yt, e2))

law sw_long.arm:
  for +xt: String
  for +yt: String
  for +b: String
  for c: Bool
  for ih: {String.starts_with.go(yt, xt ++ b) == String.starts_with.go(yt, xt)
    : Bool}
  {String.starts_with.go.if(yt, xt ++ b, c)
    == String.starts_with.go.if(yt, xt, c) : Bool}

def sw_long.arm(_xt, _yt, _b, c, ih):
  match c:
    case True{}:
      ih
    case False{}:
      {==}

law sw_long:
  for s: String
  for p: String
  for +b: String
  for e: {False{} == Nat.is_lt(String.length(s), String.length(p)) : Bool}
  {String.starts_with(s ++ b, p) == String.starts_with(s, p) : Bool}

def sw_long(s, p, b, e):
  match s p:
    case _ SNil{}:
      {==}
    case SNil{} SCon{y, yt}:
      eq.bit.absurd(&2, {String.starts_with(b, SCon{y, yt})
        == String.starts_with(SNil{}, SCon{y, yt}) : Bool}, e)
    case SCon{+x, +xt} SCon{+y, +yt}:
      sw_long.arm(xt, yt, b, Char.is_eq(x, y), sw_long(xt, yt, b, e))

law sdrop_app.arm:
  for +xt: String
  for +yt: String
  for +b: String
  for c: Bool
  for e: {True{} == String.starts_with.go.if(yt, xt, c) : Bool}
  for ih: @e2: {True{} == String.starts_with.go(yt, xt) : Bool} ->
    {String.drop(xt ++ b, String.length(yt))
      == String.drop(xt, String.length(yt)) ++ b : String}
  {String.drop(xt ++ b, String.length(yt))
    == String.drop(xt, String.length(yt)) ++ b : String}

def sdrop_app.arm(xt, yt, b, c, e, ih):
  match c:
    case True{}:
      ih(e)
    case False{}:
      eq.bit.absurd(&2, {String.drop(xt ++ b, String.length(yt))
        == String.drop(xt, String.length(yt)) ++ b : String},
        Equal.sym(Bool, True{}, False{}, e))

law sdrop_app:
  for s: String
  for p: String
  for +b: String
  for e: {True{} == String.starts_with(s, p) : Bool}
  {String.drop(s ++ b, String.length(p)) == String.drop(s, String.length(p)) ++ b
    : String}

def sdrop_app(s, p, b, e):
  match s p:
    case SNil{} SNil{}:
      eq.drop_zero(b)
    case SCon{x, xt} SNil{}:
      {==}
    case SNil{} SCon{y, yt}:
      eq.bit.absurd(&2, {String.drop(b, 1n+String.length(yt))
        == String.drop(SNil{}, 1n+String.length(yt)) ++ b : String},
        Equal.sym(Bool, True{}, False{}, e))
    case SCon{+x, +xt} SCon{+y, +yt}:
      sdrop_app.arm(xt, yt, b, Char.is_eq(x, y), e, e2 => sdrop_app(xt, yt, b, e2))

law cut_len.arm:
  for +h: Char
  for +t: String
  for +p: String
  for c: Bool
  for +ec: {c == String.starts_with(SCon{h, t}, p) : Bool}
  for e: {True{} == cut.is(Http.divide.step(c, h, t, String.length(p),
    _u => Http.divide.go(t, p, String.length(p)))) : Bool}
  for ih: @e2: {True{} == cut.is(Http.divide.go(t, p, String.length(p))) : Bool} ->
    {Nat.is_lt(String.length(t), String.length(p)) == False{} : Bool}
  {Nat.is_lt(1n+String.length(t), String.length(p)) == False{} : Bool}

def cut_len.arm(h, t, p, c, ec, e, ih):
  match c:
    case True{}:
      sw_len(SCon{h, t}, p, ec)
    case False{}:
      +ih2 = ih(Equal.trans(Bool, True{},
        cut.is(Http.divide.push(h, Http.divide.go(t, p, String.length(p)))),
        cut.is(Http.divide.go(t, p, String.length(p))), e,
        cut_is_push(h, Http.divide.go(t, p, String.length(p)))))
      lt_succ(String.length(t), String.length(p),
        Equal.sym(Bool, Nat.is_lt(String.length(t), String.length(p)), False{},
          ih2))

law cut_len:
  for s: String
  for +p: String
  for e: {True{} == cut.is(Http.divide.go(s, p, String.length(p))) : Bool}
  {Nat.is_lt(String.length(s), String.length(p)) == False{} : Bool}

def cut_len(s, p, e):
  match s:
    case SNil{}:
      eq.bit.absurd(&2, {Nat.is_lt(0n, String.length(p)) == False{} : Bool},
        Equal.sym(Bool, True{}, False{}, e))
    case SCon{+h, +t}:
      cut_len.arm(h, t, p, String.starts_with(SCon{h, t}, p), {==}, e,
        e2 => cut_len(t, p, e2))

law divide_app.arm:
  for +h: Char
  for +t: String
  for +p: String
  for +b: String
  for c: Bool
  for +ec: {c == String.starts_with(SCon{h, t}, p) : Bool}
  for e: {True{} == cut.is(Http.divide.step(c, h, t, String.length(p),
    _u => Http.divide.go(t, p, String.length(p)))) : Bool}
  for ih: @e2: {True{} == cut.is(Http.divide.go(t, p, String.length(p))) : Bool} ->
    {Http.divide.go(t ++ b, p, String.length(p))
      == cut.app(Http.divide.go(t, p, String.length(p)), b) : Http.Cut}
  {Http.divide.go(SCon{h, t ++ b}, p, String.length(p))
    == cut.app(Http.divide.step(c, h, t, String.length(p),
      _u => Http.divide.go(t, p, String.length(p))), b) : Http.Cut}

def divide_app.arm(h, t, p, b, c, ec, e, ih):
  match c:
    case True{}:
      %Equal.sym(Bool, String.starts_with(SCon{h, t} ++ b, p), True{},
        sw_app(SCon{h, t}, p, b, ec))
        : {Http.divide.step(_, h, t ++ b, String.length(p),
          _u => Http.divide.go(t ++ b, p, String.length(p)))
          == Http.Cut{"", String.drop(SCon{h, t}, String.length(p)) ++ b}
          : Http.Cut}
      Equal.cong(String, Http.Cut, x => Http.Cut{"", x},
        String.drop(SCon{h, t} ++ b, String.length(p)),
        String.drop(SCon{h, t}, String.length(p)) ++ b,
        sdrop_app(SCon{h, t}, p, b, ec))
    case False{}:
      +e2 = Equal.trans(Bool, True{},
        cut.is(Http.divide.push(h, Http.divide.go(t, p, String.length(p)))),
        cut.is(Http.divide.go(t, p, String.length(p))), e,
        cut_is_push(h, Http.divide.go(t, p, String.length(p))))
      +long = lt_succ(String.length(t), String.length(p),
        Equal.sym(Bool, Nat.is_lt(String.length(t), String.length(p)), False{},
          cut_len(t, p, e2)))
      +same = Equal.trans(Bool, String.starts_with(SCon{h, t} ++ b, p),
        String.starts_with(SCon{h, t}, p), False{},
        sw_long(SCon{h, t}, p, b, Equal.sym(Bool,
          Nat.is_lt(1n+String.length(t), String.length(p)), False{}, long)),
        Equal.sym(Bool, False{}, String.starts_with(SCon{h, t}, p), ec))
      %Equal.sym(Bool, String.starts_with(SCon{h, t} ++ b, p), False{}, same)
        : {Http.divide.step(_, h, t ++ b, String.length(p),
          _u => Http.divide.go(t ++ b, p, String.length(p)))
          == cut.app(Http.divide.push(h, Http.divide.go(t, p, String.length(p))),
            b) : Http.Cut}
      Equal.trans(Http.Cut,
        Http.divide.push(h, Http.divide.go(t ++ b, p, String.length(p))),
        Http.divide.push(h, cut.app(Http.divide.go(t, p, String.length(p)), b)),
        cut.app(Http.divide.push(h, Http.divide.go(t, p, String.length(p))), b),
        Equal.cong(Http.Cut, Http.Cut, r => Http.divide.push(h, r),
          Http.divide.go(t ++ b, p, String.length(p)),
          cut.app(Http.divide.go(t, p, String.length(p)), b), ih(e2)),
        Equal.sym(Http.Cut,
          cut.app(Http.divide.push(h, Http.divide.go(t, p, String.length(p))), b),
          Http.divide.push(h, cut.app(Http.divide.go(t, p, String.length(p)), b)),
          cut_app_push(h, Http.divide.go(t, p, String.length(p)), b)))

law divide_app:
  for s: String
  for +p: String
  for +b: String
  for e: {True{} == cut.is(Http.divide.go(s, p, String.length(p))) : Bool}
  {Http.divide.go(s ++ b, p, String.length(p))
    == cut.app(Http.divide.go(s, p, String.length(p)), b) : Http.Cut}

def divide_app(s, p, b, e):
  match s:
    case SNil{}:
      eq.bit.absurd(&2, {Http.divide.go(b, p, String.length(p))
        == cut.app(Http.NoCut{}, b) : Http.Cut},
        Equal.sym(Bool, True{}, False{}, e))
    case SCon{+h, +t}:
      divide_app.arm(h, t, p, b, String.starts_with(SCon{h, t}, p), {==}, e,
        e2 => divide_app(t, p, b, e2))

law lt0_add2:
  for o: Nat
  {Nat.is_lt(0n, Nat.add(o, 2n)) == True{} : Bool}

def lt0_add2(o):
  match o:
    case 0n:
      {==}
    case 1n+p:
      {==}

law walk_done.crlf:
  for +g: Nat
  for +l: Nat
  for +r: String
  for +after: String
  for +n: Nat
  for rd: Bool
  for +ed: {Http.octs.drop(after, Nat.add(n, 2n))
    == Http.octs.drop(r, Nat.add(l, 2n)) : String}
  for ih: @s: String ->
    {Http.walk.done(Http.walk(g, s)) == Http.chunks.ended(g, Http.divide(s, "\r\n"))
      : Bool}
  {Http.walk.done(Http.walk.crlf(g, l, r, rd, s => Http.walk(g, s)))
    == Http.chunks.ended.data(after, n, rd, cut => Http.chunks.ended(g, cut)) : Bool}

def walk_done.crlf(g, l, r, after, n, rd, ed, ih):
  match rd:
    case True{}:
      %Equal.sym(String, Http.octs.drop(after, Nat.add(n, 2n)),
        Http.octs.drop(r, Nat.add(l, 2n)), ed)
        : {Http.walk.done(Http.walk(g, Http.octs.drop(r, Nat.add(l, 2n))))
        == Http.chunks.ended(g, Http.divide(_, "\r\n")) : Bool}
      ih(Http.octs.drop(r, Nat.add(l, 2n)))
    case False{}:
      {==}

law walk_done.data.arm:
  for +g: Nat
  for +after: String
  for +n: Nat
  for sk: Http.Skip
  for +eh: {Http.octs.has(after, Nat.add(n, 2n)) == sk.has(sk, 2n) : Bool}
  for +et: {Http.octs.drop(after, n) == sk.text(sk) : String}
  for +ed: {Http.octs.drop(after, Nat.add(n, 2n)) == sk.drop(sk, 2n) : String}
  for ih: @s: String ->
    {Http.walk.done(Http.walk(g, s)) == Http.chunks.ended(g, Http.divide(s, "\r\n"))
      : Bool}
  {Http.walk.done(Http.walk.data(g, sk, s => Http.walk(g, s)))
    == Http.chunks.ended.data(after, n, Http.chunks.ready(after, n), cut => Http.chunks.ended(g, cut))
    : Bool}

def walk_done.data.arm(g, after, n, sk, eh, et, ed, ih):
  match sk:
    case Http.Short{+o}:
      +hf = Equal.trans(Bool, Http.octs.has(after, Nat.add(n, 2n)),
        Bool.not(Nat.is_lt(0n, Nat.add(o, 2n))), False{}, eh,
        Equal.cong(Bool, Bool, x => Bool.not(x), Nat.is_lt(0n, Nat.add(o, 2n)),
          True{}, lt0_add2(o)))
      %Equal.sym(Bool, Http.octs.has(after, Nat.add(n, 2n)), False{}, hf)
        : {False{} == Http.chunks.ended.data(after, n,
          Bool.and(_, String.starts_with(Http.octs.drop(after, n), "\r\n")),
          cut => Http.chunks.ended(g, cut)) : Bool}
      {==}
    case Http.Over{+l, +r}:
      %Equal.sym(Bool, Http.octs.has(after, Nat.add(n, 2n)),
        Http.octs.has(r, Nat.add(l, 2n)), eh)
        : {Http.walk.done(Http.walk.crlf(g, l, r, Bool.and(
          Http.octs.has(r, Nat.add(l, 2n)), String.starts_with(r, "\r\n")), s => Http.walk(g, s)))
          == Http.chunks.ended.data(after, n,
          Bool.and(_, String.starts_with(Http.octs.drop(after, n), "\r\n")),
          cut => Http.chunks.ended(g, cut)) : Bool}
      %Equal.sym(String, Http.octs.drop(after, n), r, et)
        : {Http.walk.done(Http.walk.crlf(g, l, r, Bool.and(
          Http.octs.has(r, Nat.add(l, 2n)), String.starts_with(r, "\r\n")), s => Http.walk(g, s)))
          == Http.chunks.ended.data(after, n,
          Bool.and(Http.octs.has(r, Nat.add(l, 2n)), String.starts_with(_, "\r\n")),
          cut => Http.chunks.ended(g, cut)) : Bool}
      walk_done.crlf(g, l, r, after, n, Bool.and(Http.octs.has(r, Nat.add(l, 2n)),
        String.starts_with(r, "\r\n")), ed, ih)

law walk_done.data:
  for +g: Nat
  for +after: String
  for +n: Nat
  for sk: Http.Skip
  for +esk: {sk == Http.octs.skip(after, n) : Http.Skip}
  for ih: @s: String ->
    {Http.walk.done(Http.walk(g, s)) == Http.chunks.ended(g, Http.divide(s, "\r\n"))
      : Bool}
  {Http.walk.done(Http.walk.data(g, sk, s => Http.walk(g, s)))
    == Http.chunks.ended.data(after, n, Http.chunks.ready(after, n), cut => Http.chunks.ended(g, cut))
    : Bool}

def walk_done.data(g, after, n, sk, esk, ih):
  +eh = Equal.trans(Bool, Http.octs.has(after, Nat.add(n, 2n)),
    sk.has(Http.octs.skip(after, n), 2n), sk.has(sk, 2n),
    skip_has(after, n, 2n),
    Equal.cong(Http.Skip, Bool, x => sk.has(x, 2n), Http.octs.skip(after, n), sk,
      Equal.sym(Http.Skip, sk, Http.octs.skip(after, n), esk)))
  +et = Equal.trans(String, Http.octs.drop(after, n),
    sk.text(Http.octs.skip(after, n)), sk.text(sk),
    skip_text(after, n),
    Equal.cong(Http.Skip, String, x => sk.text(x), Http.octs.skip(after, n), sk,
      Equal.sym(Http.Skip, sk, Http.octs.skip(after, n), esk)))
  +ed = Equal.trans(String, Http.octs.drop(after, Nat.add(n, 2n)),
    sk.drop(Http.octs.skip(after, n), 2n), sk.drop(sk, 2n),
    skip_drop(after, n, 2n),
    Equal.cong(Http.Skip, String, x => sk.drop(x, 2n), Http.octs.skip(after, n), sk,
      Equal.sym(Http.Skip, sk, Http.octs.skip(after, n), esk)))
  walk_done.data.arm(g, after, n, sk, eh, et, ed, ih)

law walk_done.trail:
  for g: Nat
  for rest: String
  for t: Bool
  {Http.walk.done(Http.walk.trail(g, rest, t)) == t : Bool}

def walk_done.trail(_g, _rest, t):
  match t:
    case True{}:
      {==}
    case False{}:
      {==}

law walk_done.size:
  for +g: Nat
  for rest: String
  for +after: String
  for +n: Nat
  for z: Bool
  for ih: @s: String ->
    {Http.walk.done(Http.walk(g, s)) == Http.chunks.ended(g, Http.divide(s, "\r\n"))
      : Bool}
  {Http.walk.done(Http.walk.size(g, rest, after, n, z, s => Http.walk(g, s)))
    == Http.chunks.ended.size(after, n, z, cut => Http.chunks.ended(g, cut)) : Bool}

def walk_done.size(g, rest, after, n, z, ih):
  match z:
    case True{}:
      walk_done.trail(g, rest, Http.chunks.trailer(after))
    case False{}:
      walk_done.data(g, after, n, Http.octs.skip(after, n), {==}, ih)

law walk_done.hex:
  for +g: Nat
  for rest: String
  for +before: String
  for +after: String
  for ok: Bool
  for ih: @s: String ->
    {Http.walk.done(Http.walk(g, s)) == Http.chunks.ended(g, Http.divide(s, "\r\n"))
      : Bool}
  {Http.walk.done(Http.walk.hex(g, rest, before, after, ok, s => Http.walk(g, s)))
    == Http.chunks.ended.hex(before, after, ok, cut => Http.chunks.ended(g, cut)) : Bool}

def walk_done.hex(g, rest, before, after, ok, ih):
  match ok:
    case False{}:
      {==}
    case True{}:
      walk_done.size(g, rest, after, Http.hexlen(before),
        Nat.is_eq(Http.hexlen(before), 0n), ih)

law walk_done.at:
  for +g: Nat
  for rest: String
  for c: Http.Cut
  for ih: @s: String ->
    {Http.walk.done(Http.walk(g, s)) == Http.chunks.ended(g, Http.divide(s, "\r\n"))
      : Bool}
  {Http.walk.done(Http.walk.at(g, rest, c, s => Http.walk(g, s)))
    == Http.chunks.ended.at(c, cut => Http.chunks.ended(g, cut)) : Bool}

def walk_done.at(g, rest, c, ih):
  match c:
    case Http.NoCut{}:
      {==}
    case Http.Cut{+before, +after}:
      walk_done.hex(g, rest, before, after,
        Http.hex.well(Http.chunks.token(before)), ih)

def Laws.walk_done(f, rest):
  match f:
    case 0n:
      {==}
    case 1n+f2:
      +g = f2
      walk_done.at(g, rest, Http.divide(rest, "\r\n"),
        s => Laws.walk_done(g, s))

law wm.ready:
  for +g: Nat
  for rest: String
  for +b: String
  for +l: Nat
  for +r: String
  for +erd: {Bool.and(Http.octs.has(r, Nat.add(l, 2n)),
    String.starts_with(r, "\r\n")) == True{} : Bool}
  for +s1: {Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b) == Http.walk.crlf(Nat.add(g,
      String.length(b)), l, r ++ b, Bool.and(
    Http.octs.has(r ++ b, Nat.add(l, 2n)), String.starts_with(r ++ b, "\r\n")), s => Http.walk(Nat.add(g,
        String.length(b)), s))
    : Http.Walk}
  for ih: @s: String ->
    {Http.walk(Nat.add(g, String.length(b)), s ++ b) == Http.walk.more(Http.walk(g, s), String.length(b), b)
      : Http.Walk}
  {Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b) == Http.walk.more(Http.walk(g, Http.octs.drop(r,
      Nat.add(l, 2n))), String.length(b), b)
    : Http.Walk}

def wm.ready(g, rest, b, l, r, erd, s1, ih):
  +eh = Equal.sym(Bool, Http.octs.has(r, Nat.add(l, 2n)), True{},
    eq.and.left(Http.octs.has(r, Nat.add(l, 2n)), String.starts_with(r, "\r\n"), erd))
  +es = Equal.sym(Bool, String.starts_with(r, "\r\n"), True{},
    eq.and.right(Http.octs.has(r, Nat.add(l, 2n)), String.starts_with(r, "\r\n"), erd))
  +h2 = has_app(r, b, Nat.add(l, 2n), eh)
  +s2 = sw_app(r, "\r\n", b, es)
  +rd2 = Equal.trans(Bool, Bool.and(Http.octs.has(r ++ b, Nat.add(l, 2n)),
      String.starts_with(r ++ b, "\r\n")),
    Bool.and(True{}, String.starts_with(r ++ b, "\r\n")), True{},
    Equal.cong(Bool, Bool, x => Bool.and(x, String.starts_with(r ++ b, "\r\n")),
      Http.octs.has(r ++ b, Nat.add(l, 2n)), True{}, h2), s2)
  Equal.trans(Http.Walk, Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b),
    Http.walk.crlf(Nat.add(g, String.length(b)), l, r ++ b, True{}, s => Http.walk(Nat.add(g, String.length(b)), s)),
    Http.walk.more(Http.walk(g, Http.octs.drop(r, Nat.add(l, 2n))), String.length(b), b),
    Equal.trans(Http.Walk, Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b),
      Http.walk.crlf(Nat.add(g, String.length(b)), l, r ++ b, Bool.and(
        Http.octs.has(r ++ b, Nat.add(l, 2n)), String.starts_with(r ++ b, "\r\n")), s => Http.walk(Nat.add(g,
            String.length(b)), s)),
      Http.walk.crlf(Nat.add(g, String.length(b)), l, r ++ b, True{}, s => Http.walk(Nat.add(g,
          String.length(b)), s)), s1,
      Equal.cong(Bool, Http.Walk, x => Http.walk.crlf(Nat.add(g, String.length(b)), l, r ++ b, x,
          s => Http.walk(Nat.add(g, String.length(b)), s)),
        Bool.and(Http.octs.has(r ++ b, Nat.add(l, 2n)),
          String.starts_with(r ++ b, "\r\n")), True{}, rd2)),
    Equal.trans(Http.Walk,
      Http.walk(Nat.add(g, String.length(b)), Http.octs.drop(r ++ b, Nat.add(l, 2n))),
      Http.walk(Nat.add(g, String.length(b)), Http.octs.drop(r, Nat.add(l, 2n)) ++ b),
      Http.walk.more(Http.walk(g, Http.octs.drop(r, Nat.add(l, 2n))), String.length(b), b),
      Equal.cong(String, Http.Walk, x => Http.walk(Nat.add(g, String.length(b)), x),
        Http.octs.drop(r ++ b, Nat.add(l, 2n)),
        Http.octs.drop(r, Nat.add(l, 2n)) ++ b, drop_app(r, b, Nat.add(l, 2n), eh)),
      ih(Http.octs.drop(r, Nat.add(l, 2n)))))

law wm.crlf:
  for +g: Nat
  for rest: String
  for +b: String
  for +l: Nat
  for +r: String
  for rd: Bool
  for +erd: {rd == Bool.and(Http.octs.has(r, Nat.add(l, 2n)),
    String.starts_with(r, "\r\n")) : Bool}
  for +s1: {Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b) == Http.walk.data(Nat.add(g,
      String.length(b)), Http.Over{l, r ++ b}, s => Http.walk(Nat.add(g, String.length(b)), s))
    : Http.Walk}
  for ih: @s: String ->
    {Http.walk(Nat.add(g, String.length(b)), s ++ b) == Http.walk.more(Http.walk(g, s), String.length(b), b)
      : Http.Walk}
  {Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b) == Http.walk.more(Http.walk.crlf(g, l, r, rd,
      s => Http.walk(g, s)), String.length(b), b) : Http.Walk}

def wm.crlf(g, rest, b, l, r, rd, erd, s1, ih):
  match rd:
    case True{}:
      wm.ready(g, rest, b, l, r, Equal.sym(Bool, True{}, Bool.and(
        Http.octs.has(r, Nat.add(l, 2n)), String.starts_with(r, "\r\n")), erd), s1, ih)
    case False{}:
      s1

law wm.data:
  for +g: Nat
  for rest: String
  for +b: String
  for sk: Http.Skip
  for +s1: {Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b) == Http.walk.data(Nat.add(g,
      String.length(b)), sk.then(sk, b), s => Http.walk(Nat.add(g, String.length(b)), s)) : Http.Walk}
  for ih: @s: String ->
    {Http.walk(Nat.add(g, String.length(b)), s ++ b) == Http.walk.more(Http.walk(g, s), String.length(b), b)
      : Http.Walk}
  {Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b) == Http.walk.more(Http.walk.data(g, sk,
      s => Http.walk(g, s)), String.length(b), b) : Http.Walk}

def wm.data(g, rest, b, sk, s1, ih):
  match sk:
    case Http.Short{o}:
      s1
    case Http.Over{+l, +r}:
      wm.crlf(g, rest, b, l, r, Bool.and(Http.octs.has(r, Nat.add(l, 2n)),
        String.starts_with(r, "\r\n")), {==}, s1, ih)

law wm.trail:
  for +g: Nat
  for +rest: String
  for +b: String
  for +after: String
  for t: Bool
  for +et: {t == Http.chunks.trailer(after) : Bool}
  for +s1: {Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b) == Http.walk.trail(Nat.add(g,
      String.length(b)), rest ++ b,
    Http.chunks.trailer(after ++ b)) : Http.Walk}
  {Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b) == Http.walk.more(Http.walk.trail(g, rest, t),
      String.length(b), b) : Http.Walk}

def wm.trail(g, rest, b, after, t, et, s1):
  match t:
    case True{}:
      Equal.trans(Http.Walk, Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b),
        Http.walk.trail(Nat.add(g, String.length(b)), rest ++ b, Http.chunks.trailer(after ++ b)),
        Http.Ended{}, s1,
        Equal.cong(Bool, Http.Walk, x => Http.walk.trail(Nat.add(g, String.length(b)), rest ++ b, x),
          Http.chunks.trailer(after ++ b), True{}, trailer_app(after, b, et)))
    case False{}:
      {==}

law wm.size:
  for +g: Nat
  for +rest: String
  for +b: String
  for +after: String
  for +n: Nat
  for z: Bool
  for +s1: {Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b) == Http.walk.size(Nat.add(g,
      String.length(b)), rest ++ b, after ++ b, n, z, s => Http.walk(Nat.add(g, String.length(b)), s))
    : Http.Walk}
  for ih: @s: String ->
    {Http.walk(Nat.add(g, String.length(b)), s ++ b) == Http.walk.more(Http.walk(g, s), String.length(b), b)
      : Http.Walk}
  {Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b) == Http.walk.more(Http.walk.size(g, rest, after, n,
      z, s => Http.walk(g, s)), String.length(b), b)
    : Http.Walk}

def wm.size(g, rest, b, after, n, z, s1, ih):
  match z:
    case True{}:
      wm.trail(g, rest, b, after, Http.chunks.trailer(after), {==}, s1)
    case False{}:
      wm.data(g, rest, b, Http.octs.skip(after, n),
        Equal.trans(Http.Walk, Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b),
          Http.walk.data(Nat.add(g, String.length(b)), Http.octs.skip(after ++ b, n),
              s => Http.walk(Nat.add(g, String.length(b)), s)),
          Http.walk.data(Nat.add(g, String.length(b)), sk.then(Http.octs.skip(after, n), b),
              s => Http.walk(Nat.add(g, String.length(b)), s)), s1,
          Equal.cong(Http.Skip, Http.Walk, x => Http.walk.data(Nat.add(g, String.length(b)), x,
              s => Http.walk(Nat.add(g, String.length(b)), s)),
            Http.octs.skip(after ++ b, n), sk.then(Http.octs.skip(after, n), b),
            skip_app(after, b, n))), ih)

law wm.hex:
  for +g: Nat
  for +rest: String
  for +b: String
  for +before: String
  for +after: String
  for ok: Bool
  for +s1: {Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b) == Http.walk.hex(Nat.add(g,
      String.length(b)), rest ++ b, before, after ++ b, ok, s => Http.walk(Nat.add(g, String.length(b)), s))
    : Http.Walk}
  for ih: @s: String ->
    {Http.walk(Nat.add(g, String.length(b)), s ++ b) == Http.walk.more(Http.walk(g, s), String.length(b), b)
      : Http.Walk}
  {Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b) == Http.walk.more(Http.walk.hex(g, rest, before,
      after, ok, s => Http.walk(g, s)), String.length(b), b)
    : Http.Walk}

def wm.hex(g, rest, b, before, after, ok, s1, ih):
  match ok:
    case False{}:
      s1
    case True{}:
      wm.size(g, rest, b, after, Http.hexlen(before),
        Nat.is_eq(Http.hexlen(before), 0n), s1, ih)

law wm.at:
  for +g: Nat
  for +rest: String
  for +b: String
  for c: Http.Cut
  for +ec: {c == Http.divide(rest, "\r\n") : Http.Cut}
  for ih: @s: String ->
    {Http.walk(Nat.add(g, String.length(b)), s ++ b) == Http.walk.more(Http.walk(g, s), String.length(b), b)
      : Http.Walk}
  {Http.walk(Nat.add(1n+g, String.length(b)), rest ++ b) == Http.walk.more(Http.walk.at(g, rest, c,
      s => Http.walk(g, s)), String.length(b), b) : Http.Walk}

def wm.at(g, rest, b, c, ec, ih):
  match c:
    case Http.NoCut{}:
      {==}
    case Http.Cut{+before, +after}:
      +cut = Equal.cong(Http.Cut, Bool, x => cut.is(x), Http.Cut{before, after},
        Http.divide(rest, "\r\n"), ec)
      +dv = Equal.trans(Http.Cut, Http.divide(rest ++ b, "\r\n"),
        cut.app(Http.divide(rest, "\r\n"), b), Http.Cut{before, after ++ b},
        divide_app(rest, "\r\n", b, cut),
        Equal.cong(Http.Cut, Http.Cut, x => cut.app(x, b), Http.divide(rest, "\r\n"),
          Http.Cut{before, after},
          Equal.sym(Http.Cut, Http.Cut{before, after}, Http.divide(rest, "\r\n"), ec)))
      wm.hex(g, rest, b, before, after, Http.hex.well(Http.chunks.token(before)),
        Equal.cong(Http.Cut, Http.Walk, x => Http.walk.at(Nat.add(g, String.length(b)), rest ++ b, x,
            s => Http.walk(Nat.add(g, String.length(b)), s)),
          Http.divide(rest ++ b, "\r\n"), Http.Cut{before, after ++ b}, dv), ih)

def Laws.walk_more(f, rest, b):
  match f:
    case 0n:
      {==}
    case 1n+f2:
      +g = f2
      wm.at(g, rest, b, Http.divide(rest, "\r\n"), {==},
        s => Laws.walk_more(g, s, b))

law hd.body:
  for f: Http.Frame
  for +after: String
  {Http.hear.done(Http.hear.body(f, after)) == Http.whole.of(f, after) : Bool}

def hd.body(f, after):
  match f:
    case Http.Bare{}:
      {==}
    case Http.Sized{n}:
      {==}
    case Http.Chunked{}:
      Laws.walk_done(String.length(after), after)
    case Http.Closed{}:
      {==}

law hd.step:
  for +g: Nat
  for +asked: Bool
  for +ls: List<&2, String>
  for +after: String
  for i: Bool
  for ih: @s: String ->
    {Http.hear.done(Http.hear.go(g, asked, s))
      == Http.whole.go(g, asked, Http.divide(s, "\r\n\r\n")) : Bool}
  {Http.hear.done(Http.hear.step(asked, ls, after, i, s => Http.hear.go(g, asked, s)))
    == Http.whole.step(asked, ls, after, i, cut => Http.whole.go(g, asked, cut)) : Bool}

def hd.step(_g, asked, ls, after, i, ih):
  match i:
    case True{}:
      ih(after)
    case False{}:
      hd.body(Http.frame(Bool.or(asked, Http.status.bare(Http.status.of(ls))),
        Http.head.go(ls, "transfer-encoding"),
        Http.head.values(ls, "content-length")), after)

law hd.at:
  for +g: Nat
  for +asked: Bool
  for raw: String
  for c: Http.Cut
  for ih: @s: String ->
    {Http.hear.done(Http.hear.go(g, asked, s))
      == Http.whole.go(g, asked, Http.divide(s, "\r\n\r\n")) : Bool}
  {Http.hear.done(Http.hear.at(g, asked, raw, c, s => Http.hear.go(g, asked, s)))
    == Http.whole.at(asked, c, cut => Http.whole.go(g, asked, cut)) : Bool}

def hd.at(g, asked, _raw, c, ih):
  match c:
    case Http.NoCut{}:
      {==}
    case Http.Cut{before, +after}:
      +ls = String.lines(before)
      hd.step(g, asked, ls, after, Http.status.interim(Http.status.of(ls)), ih)

law hd:
  for f: Nat
  for +asked: Bool
  for +raw: String
  {Http.hear.done(Http.hear.go(f, asked, raw))
    == Http.whole.go(f, asked, Http.divide(raw, "\r\n\r\n")) : Bool}

def hd(f, asked, raw):
  match f:
    case 0n:
      {==}
    case 1n+f2:
      +g = f2
      hd.at(g, asked, raw, Http.divide(raw, "\r\n\r\n"), s => hd(g, asked, s))

def Laws.hear_done(method, raw):
  hd(String.length(raw), String.eq(method, "HEAD"), raw)

law add_assoc:
  for x: Nat
  for +y: Nat
  for +z: Nat
  {Nat.add(Nat.add(x, y), z) == Nat.add(x, Nat.add(y, z)) : Nat}

def add_assoc(x, y, z):
  match x:
    case 0n:
      {==}
    case 1n+p:
      Equal.cong(Nat, Nat, k => 1n+k, Nat.add(Nat.add(p, y), z),
        Nat.add(p, Nat.add(y, z)), add_assoc(p, y, z))

law u8len_app:
  for a: String
  for +b: String
  {Http.octs.len(a ++ b) == Nat.add(Http.octs.len(a), Http.octs.len(b)) : Nat}

def u8len_app(a, b):
  match a:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      +w = Http.octs.width(Char.to_u32(h))
      Equal.trans(Nat, Nat.add(w, Http.octs.len(t ++ b)),
        Nat.add(w, Nat.add(Http.octs.len(t), Http.octs.len(b))),
        Nat.add(Nat.add(w, Http.octs.len(t)), Http.octs.len(b)),
        Equal.cong(Nat, Nat, k => Nat.add(w, k), Http.octs.len(t ++ b),
          Nat.add(Http.octs.len(t), Http.octs.len(b)), u8len_app(t, b)),
        Equal.sym(Nat, Nat.add(Nat.add(w, Http.octs.len(t)), Http.octs.len(b)),
          Nat.add(w, Nat.add(Http.octs.len(t), Http.octs.len(b))),
          add_assoc(w, Http.octs.len(t), Http.octs.len(b))))

law hm.body:
  for f: Http.Frame
  for +after: String
  for +b: String
  {Http.hear.body(f, after ++ b) == Http.hear.more(Http.hear.body(f, after), b)
    : Http.Hear}

def hm.body(f, after, b):
  match f:
    case Http.Bare{}:
      {==}
    case Http.Sized{+n}:
      Equal.cong(Nat, Http.Hear, k => Http.Count{n, k}, Http.octs.len(after ++ b),
        Nat.add(Http.octs.len(after), Http.octs.len(b)), u8len_app(after, b))
    case Http.Chunked{}:
      Equal.cong(Http.Walk, Http.Hear, w => Http.Walking{w},
        Http.walk(String.length(after ++ b), after ++ b),
        Http.walk.more(Http.walk(String.length(after), after), String.length(b), b),
        Equal.trans(Http.Walk, Http.walk(String.length(after ++ b), after ++ b),
          Http.walk(Nat.add(String.length(after), String.length(b)), after ++ b),
          Http.walk.more(Http.walk(String.length(after), after), String.length(b), b),
          Equal.cong(Nat, Http.Walk, k => Http.walk(k, after ++ b),
            String.length(after ++ b), Nat.add(String.length(after), String.length(b)),
            len_app(after, b)),
          Laws.walk_more(String.length(after), after, b)))
    case Http.Closed{}:
      {==}

law hm.step:
  for +g: Nat
  for +asked: Bool
  for +raw: String
  for +b: String
  for +ls: List<&2, String>
  for +after: String
  for i: Bool
  for +s1: {Http.hear.go(Nat.add(1n+g, String.length(b)), asked, raw ++ b) == Http.hear.step(asked, ls,
      after ++ b, i, s => Http.hear.go(Nat.add(g, String.length(b)), asked, s)) : Http.Hear}
  for ih: @s: String ->
    {Http.hear.go(Nat.add(g, String.length(b)), asked, s ++ b)
      == Http.hear.more(Http.hear.go(g, asked, s), b) : Http.Hear}
  {Http.hear.go(Nat.add(1n+g, String.length(b)), asked, raw ++ b) == Http.hear.more(Http.hear.step(asked, ls,
      after, i, s => Http.hear.go(g, asked, s)), b)
    : Http.Hear}

def hm.step(g, asked, raw, b, ls, after, i, s1, ih):
  match i:
    case True{}:
      Equal.trans(Http.Hear, Http.hear.go(Nat.add(1n+g, String.length(b)), asked, raw ++ b),
          Http.hear.go(Nat.add(g, String.length(b)), asked, after ++ b),
        Http.hear.more(Http.hear.go(g, asked, after), b), s1, ih(after))
    case False{}:
      +fr = Http.frame(Bool.or(asked, Http.status.bare(Http.status.of(ls))),
        Http.head.go(ls, "transfer-encoding"),
        Http.head.values(ls, "content-length"))
      Equal.trans(Http.Hear, Http.hear.go(Nat.add(1n+g, String.length(b)), asked, raw ++ b),
          Http.hear.body(fr, after ++ b),
        Http.hear.more(Http.hear.body(fr, after), b), s1, hm.body(fr, after, b))

law hm.at:
  for +g: Nat
  for +asked: Bool
  for +raw: String
  for +b: String
  for c: Http.Cut
  for +ec: {c == Http.divide(raw, "\r\n\r\n") : Http.Cut}
  for ih: @s: String ->
    {Http.hear.go(Nat.add(g, String.length(b)), asked, s ++ b)
      == Http.hear.more(Http.hear.go(g, asked, s), b) : Http.Hear}
  {Http.hear.go(Nat.add(1n+g, String.length(b)), asked, raw ++ b) == Http.hear.more(Http.hear.at(g, asked,
      raw, c, s => Http.hear.go(g, asked, s)), b) : Http.Hear}

def hm.at(g, asked, raw, b, c, ec, ih):
  match c:
    case Http.NoCut{}:
      {==}
    case Http.Cut{+before, +after}:
      +cut = Equal.cong(Http.Cut, Bool, x => cut.is(x), Http.Cut{before, after},
        Http.divide(raw, "\r\n\r\n"), ec)
      +dv = Equal.trans(Http.Cut, Http.divide(raw ++ b, "\r\n\r\n"),
        cut.app(Http.divide(raw, "\r\n\r\n"), b), Http.Cut{before, after ++ b},
        divide_app(raw, "\r\n\r\n", b, cut),
        Equal.cong(Http.Cut, Http.Cut, x => cut.app(x, b), Http.divide(raw, "\r\n\r\n"),
          Http.Cut{before, after},
          Equal.sym(Http.Cut, Http.Cut{before, after}, Http.divide(raw, "\r\n\r\n"), ec)))
      +ls = String.lines(before)
      hm.step(g, asked, raw, b, ls, after, Http.status.interim(Http.status.of(ls)),
        Equal.cong(Http.Cut, Http.Hear,
          x => Http.hear.at(Nat.add(g, String.length(b)), asked, raw ++ b, x, s => Http.hear.go(Nat.add(g,
              String.length(b)), asked, s)),
          Http.divide(raw ++ b, "\r\n\r\n"), Http.Cut{before, after ++ b}, dv), ih)

law hm:
  for f: Nat
  for +asked: Bool
  for +raw: String
  for +b: String
  {Http.hear.go(Nat.add(f, String.length(b)), asked, raw ++ b)
    == Http.hear.more(Http.hear.go(f, asked, raw), b) : Http.Hear}

def hm(f, asked, raw, b):
  match f:
    case 0n:
      {==}
    case 1n+f2:
      +g = f2
      hm.at(g, asked, raw, b, Http.divide(raw, "\r\n\r\n"), {==}, s => hm(g, asked, s, b))

def Laws.hear_more(method, a, b):
  +asked = String.eq(method, "HEAD")
  Equal.sym(Http.Hear, Http.hear.of(method, a ++ b),
    Http.hear.more(Http.hear.of(method, a), b),
    Equal.trans(Http.Hear, Http.hear.go(String.length(a ++ b), asked, a ++ b),
      Http.hear.go(Nat.add(String.length(a), String.length(b)), asked, a ++ b),
      Http.hear.more(Http.hear.go(String.length(a), asked, a), b),
      Equal.cong(Nat, Http.Hear, k => Http.hear.go(k, asked, a ++ b),
        String.length(a ++ b), Nat.add(String.length(a), String.length(b)), len_app(a, b)),
      hm(String.length(a), asked, a, b)))

def Laws.read_fail(st, got, e):
  %e : {Spec.wire.read.of(st, got, _) == Spec.Heard{got} : Spec.Read}
  {==}

law app_nil:
  for x: String
  {x ++ "" == x : String}

def app_nil(x):
  match x:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      Equal.cong(String, String, r => SCon{h, r}, t ++ "", t, app_nil(t))

law app_assoc:
  for x: String
  for +y: String
  for +z: String
  {(x ++ y) ++ z == x ++ (y ++ z) : String}

def app_assoc(x, y, z):
  match x:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      Equal.cong(String, String, r => SCon{h, r}, (t ++ y) ++ z, t ++ (y ++ z),
        app_assoc(t, y, z))

law join_go:
  for ps: List<&2, String>
  for +acc: String
  {Spec.wire.join.go(ps, acc) == Spec.wire.joined(ps) ++ acc : String}

def join_go(ps, acc):
  match ps:
    case []:
      {==}
    case +p <> +rest:
      Equal.trans(String, Spec.wire.join.go(rest, p ++ acc),
        Spec.wire.joined(rest) ++ (p ++ acc),
        (Spec.wire.joined(rest) ++ p) ++ acc,
        join_go(rest, p ++ acc),
        Equal.sym(String, (Spec.wire.joined(rest) ++ p) ++ acc,
          Spec.wire.joined(rest) ++ (p ++ acc),
          app_assoc(Spec.wire.joined(rest), p, acc)))

def Laws.join_joined(ps):
  Equal.trans(String, Spec.wire.join.go(ps, ""), Spec.wire.joined(ps) ++ "",
    Spec.wire.joined(ps), join_go(ps, ""), app_nil(Spec.wire.joined(ps)))

def Laws.read_closed(ps, _h):
  Equal.cong(String, Spec.Read, x => Spec.Heard{"0\n" ++ x},
    Spec.wire.join(ps), Spec.wire.joined(ps), Laws.join_joined(ps))

def Laws.read_whole(method, ps, text, e1, e2):
  +J = Spec.wire.joined(ps)
  +H0 = Http.hear.of(method, J)
  +dz = Equal.sym(String, String.drop(text, 0n), text, eq.drop_zero(text))
  %dz : {Spec.wire.read.got(Spec.Got{ps, H0}, _, String.is_empty(_)) == Spec.Heard{"0\n" ++ (J ++ text)}
    : Spec.Read}
  %e1 : {Spec.wire.read.got(Spec.Got{ps, H0}, text, _) == Spec.Heard{"0\n" ++ (J ++ text)} : Spec.Read}
  %Equal.sym(Http.Hear, Http.hear.more(H0, text), Http.hear.of(method, J ++ text),
    Laws.hear_more(method, J, text))
    : {Spec.wire.read.whole(text <> ps, _, Http.hear.done(_)) == Spec.Heard{"0\n" ++ (J ++ text)} : Spec.Read}
  %Equal.sym(Bool, Http.hear.done(Http.hear.of(method, J ++ text)),
    Http.whole(method, J ++ text), Laws.hear_done(method, J ++ text))
    : {Spec.wire.read.whole(text <> ps, Http.hear.of(method, J ++ text), _) == Spec.Heard{"0\n" ++ (J ++ text)}
      : Spec.Read}
  %e2 : {Spec.wire.read.whole(text <> ps, Http.hear.of(method, J ++ text), _)
    == Spec.Heard{"0\n" ++ (J ++ text)} : Spec.Read}
  Equal.cong(String, Spec.Read, x => Spec.Heard{"0\n" ++ x},
    Spec.wire.join(text <> ps), J ++ text, Laws.join_joined(text <> ps))

def Laws.read_more(method, ps, text, e1, e2):
  +J = Spec.wire.joined(ps)
  +H0 = Http.hear.of(method, J)
  +dz = Equal.sym(String, String.drop(text, 0n), text, eq.drop_zero(text))
  %dz : {Spec.wire.read.got(Spec.Got{ps, H0}, _, String.is_empty(_)) == Spec.Again{Spec.wire.got(method, text <> ps)}
    : Spec.Read}
  %e1 : {Spec.wire.read.got(Spec.Got{ps, H0}, text, _) == Spec.Again{Spec.wire.got(method, text <> ps)} : Spec.Read}
  %Equal.sym(Http.Hear, Http.hear.more(H0, text), Http.hear.of(method, J ++ text),
    Laws.hear_more(method, J, text))
    : {Spec.wire.read.whole(text <> ps, _, Http.hear.done(_)) == Spec.Again{Spec.wire.got(method,
        text <> ps)} : Spec.Read}
  %Equal.sym(Bool, Http.hear.done(Http.hear.of(method, J ++ text)),
    Http.whole(method, J ++ text), Laws.hear_done(method, J ++ text))
    : {Spec.wire.read.whole(text <> ps, Http.hear.of(method, J ++ text),
        _) == Spec.Again{Spec.wire.got(method, text <> ps)}
      : Spec.Read}
  %e2 : {Spec.wire.read.whole(text <> ps, Http.hear.of(method, J ++ text), _)
    == Spec.Again{Spec.wire.got(method, text <> ps)} : Spec.Read}
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

# --- octet bodies, responses by method, multipart forms (HTTP-CLI-10, 10, HTTP-FORM) ---

def Laws.whole_go(_method, _raw):
  {==}

def Laws.whole_fuel(_asked, _c):
  {==}

def Laws.whole_interim(f, asked, before, after, e):
  %e : {Http.whole.step(asked, String.lines(before), after, _,
    cut => Http.whole.go(f, asked, cut))
    == Http.whole.go(f, asked, Http.divide(after, "\r\n\r\n")) : Bool}
  {==}

def Laws.status_interim_some(_n):
  {==}

def Laws.status_interim_none(_m, e):
  %e : {Http.status.interim(_) == False{} : Bool}
  {==}

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
  hd.of_fields(Http.FClen{},
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
      hd.or_gone(Http.FClen{}, Http.fields.of(Http.FHost{}, hs),
        [Http.H{"Host", host}],
      hd.disj(Http.FClen{}, Http.FHost{}, {==}, hs), {==}),
      hd.or_gone(Http.FClen{}, Http.fields.of(Http.FAgent{}, hs),
        [Http.H{"User-Agent", "ezhttp"}],
      hd.disj(Http.FClen{}, Http.FAgent{}, {==}, hs), {==}),
      hd.or_gone(Http.FClen{}, Http.fields.of(Http.FAccept{}, hs),
        [Http.H{"Accept", "*/*"}],
      hd.disj(Http.FClen{}, Http.FAccept{}, {==}, hs), {==}),
      Equal.sym(List<&2, Http.Header>,
        Http.fields.of(Http.FClen{}, Http.fields.of(Http.FOther{}, hs)), [],
      hd.disj(Http.FClen{}, Http.FOther{}, {==}, hs)),
      hd.clen_self(n, Nat.is_eq(n, 0n)))

def Laws.reply_to(_method, _raw):
  {==}

def Laws.reply_fuel(_head, _c):
  {==}

def Laws.reply_open(_f, _head):
  {==}

def Laws.reply_interim(f, head, before, after, e):
  %e : {Http.parse.to.step(head, String.lines(before), Http.status.of(String.lines(before)), after, _,
    cut => Http.parse.to.go(f, head, cut))
    == Http.parse.to.go(f, head, Http.divide(after, "\r\n\r\n"))
    : Http.Reply}
  {==}

def Laws.reply_bare(f, head, before, after, e1, e2, n, e3):
  %e1 : {Http.parse.to.step(head, String.lines(before), Http.status.of(String.lines(before)), after, _,
    cut => Http.parse.to.go(f, head, cut))
    == Http.Reply{n, Http.head.list(String.lines(before)), ""} : Http.Reply}
  %e2 : {Http.parse.to.final(Http.status.of(String.lines(before)), String.lines(before), after, _)
    == Http.Reply{n, Http.head.list(String.lines(before)), ""} : Http.Reply}
  %e3 : {Http.parse.to.bare(_, String.lines(before))
    == Http.Reply{n, Http.head.list(String.lines(before)), ""} : Http.Reply}
  {==}

def Laws.reply_bare_none(f, head, before, after, e1, e2, e3):
  %e1 : {Http.parse.to.step(head, String.lines(before), Http.status.of(String.lines(before)), after, _,
    cut => Http.parse.to.go(f, head, cut))
    == Http.Torn{"the response has no status line"} : Http.Reply}
  %e2 : {Http.parse.to.final(Http.status.of(String.lines(before)), String.lines(before), after, _)
    == Http.Torn{"the response has no status line"} : Http.Reply}
  %e3 : {Http.parse.to.bare(_, String.lines(before))
    == Http.Torn{"the response has no status line"} : Http.Reply}
  {==}

def Laws.reply_framed(f, head, before, after, e1, e2):
  %e1 : {Http.parse.to.step(head, String.lines(before), Http.status.of(String.lines(before)), after, _,
    cut => Http.parse.to.go(f, head, cut))
    == Http.parse.head(String.lines(before), after) : Http.Reply}
  %e2 : {Http.parse.to.final(Http.status.of(String.lines(before)), String.lines(before), after, _)
    == Http.parse.head(String.lines(before), after) : Http.Reply}
  {==}

def Laws.interim_skip(_m, _after):
  {==}

def Laws.status_empty(_m):
  {==}

def Laws.heard_ok(method, text):
  dz = Equal.sym(String, String.drop(text, 0n), text, eq.drop_zero(text))
  %dz : {Http.parse.to(method, _) == Http.parse.to(method, text) : Http.Reply}
  {==}

def Laws.heard_fail(method, raw, e):
  %e : {Spec.wire.heard.of(method, raw, _)
    == Http.Torn{Spec.wire.why(Spec.wire.code(raw), Spec.wire.text(raw))}
    : Http.Reply}
  {==}

def Laws.all_step(ok, _rest):
  match ok:
    case False{}:
      {==}
    case True{}:
      {==}

def Laws.any_step(hit, _rest):
  match hit:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.form_bad_boundary(b, ps, e):
  %e : {Form.form.check(b, ps, _)
    == Form.NoPlan{"the boundary must be 1 to 70 of A-Z a-z 0-9 - _ ."}
    : Form.Plan}
  {==}

def Laws.form_clash(b, ps, e1, e2):
  %e1 : {Form.form.check(b, ps, _)
    == Form.NoPlan{"the boundary occurs in a part's content"} : Form.Plan}
  %e2 : {Form.form.check.clash(b, ps, _)
    == Form.NoPlan{"the boundary occurs in a part's content"} : Form.Plan}
  {==}

def Laws.form_bad_type(b, ps, e1, e2, e3):
  %e1 : {Form.form.check(b, ps, _)
    == Form.NoPlan{"a file part's content type holds a CR or LF"} : Form.Plan}
  %e2 : {Form.form.check.clash(b, ps, _)
    == Form.NoPlan{"a file part's content type holds a CR or LF"} : Form.Plan}
  %e3 : {Form.form.check.type(b, ps, _)
    == Form.NoPlan{"a file part's content type holds a CR or LF"} : Form.Plan}
  {==}

def Laws.form_ok(b, ps, e1, e2, e3):
  %e1 : {Form.form.check(b, ps, _)
    == Form.Plan{Form.form.type(b), Form.form.parts(b, ps)}
    : Form.Plan}
  %e2 : {Form.form.check.clash(b, ps, _)
    == Form.Plan{Form.form.type(b), Form.form.parts(b, ps)}
    : Form.Plan}
  %e3 : {Form.form.check.type(b, ps, _)
    == Form.Plan{Form.form.type(b), Form.form.parts(b, ps)}
    : Form.Plan}
  {==}

def Laws.form_type(_b):
  {==}

def Laws.boundary_ok(_b):
  {==}

def Laws.bchar(_cp):
  {==}

def Laws.bchars_nil(_s, e):
  %e : {Form.form.bchars(_) == True{} : Bool}
  {==}

def Laws.bchars_cons(c, t):
  Laws.all_step(Form.form.bchar(c), _u => Form.form.bchars(t))

def Laws.delim(_b):
  {==}

def Laws.clash_nil(_b):
  {==}

def Laws.clash_cons(b, p, t):
  Laws.any_step(Form.form.hit(b, p), _u => Form.form.clash(b, t))

def Laws.has_nil(_pat):
  {==}

def Laws.has_cons(x, t, pat):
  Laws.any_step(Form.octets.starts(x <> t, pat), _u => Form.octets.has(t, pat))

def Laws.starts_done(xs):
  match xs:
    case []:
      {==}
    case _x <> _t:
      {==}

def Laws.starts_short(_p, _q):
  {==}

def Laws.starts_cons(x, t, p, q):
  Laws.all_step(U32.is_eq(x, p), _u => Form.octets.starts(t, q))

def Laws.content_field(_name, _value, _rest):
  {==}

def Laws.content_file(_name, _filename, _ctype, _clash, _rest):
  {==}

def Laws.badtype_nil(_ps, e):
  %e : {Form.form.badtype(_) == False{} : Bool}
  {==}

def Laws.badtype_cons(p, t):
  Laws.any_step(Form.form.badtype.one(p), _u => Form.form.badtype(t))

def Laws.badtype_field(_name, _value):
  {==}

def Laws.badtype_file(_name, _filename, _ctype, _clash):
  {==}

def Laws.parts_nil(_b):
  {==}

def Laws.parts_cons(_b, _p, _t):
  {==}

def Laws.part(_b, _p, _rest):
  {==}

def Laws.onto_nil(_rest):
  {==}

def Laws.onto_cons(_c, _t, _rest):
  {==}

def Laws.field_is(_d, _name, _value):
  {==}

def Laws.file_is(_name, _filename, _ctype, _n, _buf, _hit):
  {==}

def Laws.head_field(_name, _value):
  {==}

def Laws.head_file(_name, _filename, _ctype, _clash):
  {==}

def Laws.disposition(_name):
  {==}

def Laws.fq_nil(_s, e):
  %e : {Form.form.quote(_) == "" : String}
  {==}

def Laws.fq_cons(_c, _t):
  {==}

def Laws.fq_dq(_rest):
  {==}

def Laws.fq_cr(_rest):
  {==}

def Laws.fq_lf(_rest):
  {==}

def Laws.fq_other(c, e1, e2, e3, rest):
  %e1 : {Form.form.one.dq(c, rest, _) == SCon{Chr{c}, rest} : String}
  %e2 : {Form.form.one.cr(c, rest, _) == SCon{Chr{c}, rest} : String}
  %e3 : {Form.form.one.lf(c, rest, _) == SCon{Chr{c}, rest} : String}
  {==}

# --- a response's reason phrase (SPEC.md HTTP-CLI-11) ---

def Laws.phrase_to(_raw):
  {==}

def Laws.phrase_fuel(_c):
  {==}

def Laws.phrase_open(_f):
  {==}

def Laws.phrase_interim(f, before, after, e):
  %e : {Http.phrase.to.step(String.lines(before), after, _,
    cut => Http.phrase.to.go(f, cut))
    == Http.phrase.to.go(f, Http.divide(after, "\r\n\r\n")) : String}
  {==}

def Laws.phrase_final(f, before, after, e):
  %e : {Http.phrase.to.step(String.lines(before), after, _,
    cut => Http.phrase.to.go(f, cut))
    == Http.phrase.line(Http.first(String.lines(before))) : String}
  {==}

# LAW: a string that avoids a character does not start with it
law avoids.head:
  for +h: Char
  for +t: String
  for +c: Char
  for e: {True{} == Laws.avoids(SCon{h, t}, c) : Bool}
  {False{} == Char.is_eq(h, c) : Bool}

def avoids.head(h, t, c, e):
  Equal.sym(Bool, Char.is_eq(h, c), False{},
    eq.not.true(Char.is_eq(h, c),
      eq.and.left(Bool.not(Char.is_eq(h, c)), Laws.avoids(t, c),
        Equal.sym(Bool, True{}, Laws.avoids(SCon{h, t}, c), e))))

# LAW: a string that avoids a character has a tail that avoids it
law avoids.tail:
  for +h: Char
  for +t: String
  for +c: Char
  for e: {True{} == Laws.avoids(SCon{h, t}, c) : Bool}
  {True{} == Laws.avoids(t, c) : Bool}

def avoids.tail(h, t, c, e):
  Equal.sym(Bool, Laws.avoids(t, c), True{},
    eq.and.right(Bool.not(Char.is_eq(h, c)), Laws.avoids(t, c),
      Equal.sym(Bool, True{}, Laws.avoids(SCon{h, t}, c), e)))

# LAW: one step of dividing at the first SP, past a character that is not one
law sp_cut.step:
  for +h: Char
  for +t: String
  for +b: String
  for f: {False{} == Char.is_eq(h, ' ') : Bool}
  for ih: {Http.divide.go(String.append(t, SCon{' ', b}), " ", 1n)
    == Http.Cut{t, b} : Http.Cut}
  {Http.divide.go(String.append(SCon{h, t}, SCon{' ', b}), " ", 1n)
    == Http.Cut{SCon{h, t}, b} : Http.Cut}

def sp_cut.step(h, t, b, f, ih):
  %f : {Http.divide.step(
    String.starts_with.go.if("", String.append(t, SCon{' ', b}), _), h,
    String.append(t, SCon{' ', b}), 1n,
    _u => Http.divide.go(String.append(t, SCon{' ', b}), " ", 1n))
    == Http.Cut{SCon{h, t}, b} : Http.Cut}
  Equal.cong(Http.Cut, Http.Cut, r => Http.divide.push(h, r),
    Http.divide.go(String.append(t, SCon{' ', b}), " ", 1n), Http.Cut{t, b},
    ih)

# LAW: a text that holds no SP before one divides there
law sp_cut:
  for +a: String
  for +b: String
  for +e: {True{} == Laws.avoids(a, ' ') : Bool}
  {Http.divide.go(String.append(a, SCon{' ', b}), " ", 1n)
    == Http.Cut{a, b} : Http.Cut}

def sp_cut(a, b, e):
  match a:
    case SNil{}:
      Equal.cong(String, Http.Cut, x => Http.Cut{"", x}, String.drop(b, 0n),
        b, eq.drop_zero(b))
    case SCon{+h, +t}:
      sp_cut.step(h, t, b, avoids.head(h, t, ' ', e),
        sp_cut(t, b, avoids.tail(h, t, ' ', e)))

# LAW: one step of dividing a text with no SP
law sp_none.step:
  for +h: Char
  for +t: String
  for f: {False{} == Char.is_eq(h, ' ') : Bool}
  for ih: {Http.divide.go(t, " ", 1n) == Http.NoCut{} : Http.Cut}
  {Http.divide.go(SCon{h, t}, " ", 1n) == Http.NoCut{} : Http.Cut}

def sp_none.step(h, t, f, ih):
  %f : {Http.divide.step(String.starts_with.go.if("", t, _), h, t, 1n,
    _u => Http.divide.go(t, " ", 1n)) == Http.NoCut{} : Http.Cut}
  Equal.cong(Http.Cut, Http.Cut, r => Http.divide.push(h, r),
    Http.divide.go(t, " ", 1n), Http.NoCut{}, ih)

# LAW: a text with no SP does not divide at one
law sp_none:
  for +a: String
  for +e: {True{} == Laws.avoids(a, ' ') : Bool}
  {Http.divide.go(a, " ", 1n) == Http.NoCut{} : Http.Cut}

def sp_none(a, e):
  match a:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      sp_none.step(h, t, avoids.head(h, t, ' ', e),
        sp_none(t, avoids.tail(h, t, ' ', e)))

# LAW: one step of the chop, past a character that is not CR
law chop.step:
  for +h: Char
  for +t: String
  for +x: String
  for f: {False{} == Char.is_eq(h, '\r') : Bool}
  for ih: {Http.phrase.chop(x) == t : String}
  {Http.phrase.chop(SCon{h, x}) == SCon{h, t} : String}

def chop.step(h, t, x, f, ih):
  %f : {Http.phrase.chop.at(_, h, x, _u => Http.phrase.chop(x))
    == SCon{h, t} : String}
  Equal.cong(String, String, y => SCon{h, y}, Http.phrase.chop(x), t, ih)

# LAW: a text with no CR is its own chop
law chop.keep:
  for +r: String
  for +e: {True{} == Laws.avoids(r, '\r') : Bool}
  {Http.phrase.chop(r) == r : String}

def chop.keep(r, e):
  match r:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      chop.step(h, t, t, avoids.head(h, t, '\r', e),
        chop.keep(t, avoids.tail(h, t, '\r', e)))

# LAW: the chop of a text with no CR and then a CR is the text
law chop.cr:
  for +r: String
  for +e: {True{} == Laws.avoids(r, '\r') : Bool}
  {Http.phrase.chop(String.append(r, "\r")) == r : String}

def chop.cr(r, e):
  match r:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      chop.step(h, t, String.append(t, "\r"), avoids.head(h, t, '\r', e),
        chop.cr(t, avoids.tail(h, t, '\r', e)))

def Laws.phrase_line(v, c, r, e1, e2, e3):
  Equal.trans(String,
    Http.phrase.line(String.append(v, SCon{' ', String.append(c, SCon{' ', r})})),
    Http.phrase.code(Http.Cut{c, r}),
    r,
    Equal.trans(String,
      Http.phrase.line(String.append(v, SCon{' ', String.append(c, SCon{' ', r})})),
      Http.phrase.after(Http.Cut{v, String.append(c, SCon{' ', r})}),
      Http.phrase.code(Http.Cut{c, r}),
      Equal.cong(Http.Cut, String, k => Http.phrase.after(k),
        Http.divide.go(String.append(v, SCon{' ', String.append(c, SCon{' ', r})}), " ", 1n),
        Http.Cut{v, String.append(c, SCon{' ', r})},
        sp_cut(v, String.append(c, SCon{' ', r}), e1)),
      Equal.cong(Http.Cut, String, k => Http.phrase.code(k),
        Http.divide.go(String.append(c, SCon{' ', r}), " ", 1n),
        Http.Cut{c, r}, sp_cut(c, r, e2))),
    chop.keep(r, e3))

def Laws.phrase_line_cr(v, c, r, e1, e2, e3):
  Equal.trans(String,
    Http.phrase.line(String.append(v, SCon{' ', String.append(c,
      SCon{' ', String.append(r, "\r")})})),
    Http.phrase.code(Http.Cut{c, String.append(r, "\r")}),
    r,
    Equal.trans(String,
      Http.phrase.line(String.append(v, SCon{' ', String.append(c,
        SCon{' ', String.append(r, "\r")})})),
      Http.phrase.after(Http.Cut{v, String.append(c,
        SCon{' ', String.append(r, "\r")})}),
      Http.phrase.code(Http.Cut{c, String.append(r, "\r")}),
      Equal.cong(Http.Cut, String, k => Http.phrase.after(k),
        Http.divide.go(String.append(v, SCon{' ', String.append(c,
          SCon{' ', String.append(r, "\r")})}), " ", 1n),
        Http.Cut{v, String.append(c, SCon{' ', String.append(r, "\r")})},
        sp_cut(v, String.append(c, SCon{' ', String.append(r, "\r")}), e1)),
      Equal.cong(Http.Cut, String, k => Http.phrase.code(k),
        Http.divide.go(String.append(c, SCon{' ', String.append(r, "\r")}),
          " ", 1n),
        Http.Cut{c, String.append(r, "\r")},
        sp_cut(c, String.append(r, "\r"), e2))),
    chop.cr(r, e3))

def Laws.phrase_line_one(v, c, e1, e2):
  Equal.trans(String,
    Http.phrase.line(String.append(v, SCon{' ', c})),
    Http.phrase.after(Http.Cut{v, c}),
    "",
    Equal.cong(Http.Cut, String, k => Http.phrase.after(k),
      Http.divide.go(String.append(v, SCon{' ', c}), " ", 1n),
      Http.Cut{v, c}, sp_cut(v, c, e1)),
    Equal.cong(Http.Cut, String, k => Http.phrase.code(k),
      Http.divide.go(c, " ", 1n), Http.NoCut{}, sp_none(c, e2)))

def Laws.phrase_line_none(v, e):
  Equal.cong(Http.Cut, String, k => Http.phrase.after(k),
    Http.divide.go(v, " ", 1n), Http.NoCut{}, sp_none(v, e))

def Laws.phrase_heard(text):
  dz = Equal.sym(String, String.drop(text, 0n), text, eq.drop_zero(text))
  %dz : {Http.phrase.to(_) == Http.phrase.to(text) : String}
  {==}

# --- percent-decoding and query strings (SPEC.md HTTP-QS) ---

def Laws.qs_unquote(_s):
  {==}

def Laws.qs_unquote_plus(_s):
  {==}

def Laws.qs_toks_nil(_plus, _st):
  {==}

def Laws.qs_toks_cons(_c, _t, _plus, _st):
  {==}

def Laws.qs_tok_wide(plus, c, k, e):
  %e : {Qs.tok.wide(plus, c, k, _) == Qs.W{c} <> k(Qs.Plain{})
    : List<&2, Qs.Tok>}
  {==}

def Laws.qs_tok_open(plus, c, k, e1, e2):
  %e1 : {Qs.tok.wide(plus, c, k, _) == k(Qs.Pct{}) : List<&2, Qs.Tok>}
  %e2 : {Qs.tok.ascii(plus, c, k, _) == k(Qs.Pct{}) : List<&2, Qs.Tok>}
  {==}

def Laws.qs_tok_byte(plus, c, k, e1, e2):
  %e1 : {Qs.tok.wide(plus, c, k, _)
    == Qs.B{Qs.tok.byte(plus, c)} <> k(Qs.Plain{}) : List<&2, Qs.Tok>}
  %e2 : {Qs.tok.ascii(plus, c, k, _)
    == Qs.B{Qs.tok.byte(plus, c)} <> k(Qs.Plain{}) : List<&2, Qs.Tok>}
  {==}

def Laws.qs_byte_plus(c, e):
  %e : {Bool.pick(U32, Bool.and(True{}, _), 32, Char.to_u32(c)) == 32 : U32}
  {==}

def Laws.qs_byte_other(_plus, c, e):
  %e : {Bool.pick(U32, _, 32, Char.to_u32(c)) == Char.to_u32(c) : U32}
  {==}

def Laws.qs_tok_pct_hex(plus, c, k, e):
  %e : {Qs.tok.pct(plus, c, k, _) == k(Qs.Pct1{c}) : List<&2, Qs.Tok>}
  {==}

def Laws.qs_tok_pct_other(plus, c, k, e):
  %e : {Qs.tok.pct(plus, c, k, _)
    == Qs.B{37} <> Qs.tok.step(plus, Qs.Plain{}, c, k) : List<&2, Qs.Tok>}
  {==}

def Laws.qs_tok_pct1_hex(plus, d, c, k, e):
  %e : {Qs.tok.pct1(plus, d, c, k, _)
    == Qs.B{U32.add(U32.mul(Http.hex.val(d), 16), Http.hex.val(c))}
      <> k(Qs.Plain{}) : List<&2, Qs.Tok>}
  {==}

def Laws.qs_tok_pct1_other(plus, d, c, k, e):
  %e : {Qs.tok.pct1(plus, d, c, k, _)
    == Qs.B{37} <> (Qs.B{Char.to_u32(d)}
      <> Qs.tok.step(plus, Qs.Plain{}, c, k)) : List<&2, Qs.Tok>}
  {==}

def Laws.qs_tok_end_plain(_st, e):
  %e : {Qs.tok.end(_) == [] : List<&2, Qs.Tok>}
  {==}

def Laws.qs_tok_end_pct(_st, e):
  %e : {Qs.tok.end(_) == [Qs.B{37}] : List<&2, Qs.Tok>}
  {==}

def Laws.qs_tok_end_pct1(_d):
  {==}

def Laws.qs_tok_hex(_c):
  {==}

def Laws.qs_hexval_dec(u, e):
  %e : {Bool.pick(U32, _, U32.sub(u, 48),
    Bool.pick(U32, Bool.and(U32.is_ge(u, 97), U32.is_le(u, 102)),
      U32.sub(u, 87),
      Bool.pick(U32, Bool.and(U32.is_ge(u, 65), U32.is_le(u, 70)),
        U32.sub(u, 55), 16))) == U32.sub(u, 48) : U32}
  {==}

def Laws.qs_hexval_upper(u, e1, e2, e3):
  %e1 : {Bool.pick(U32, _, U32.sub(u, 48),
    Bool.pick(U32, Bool.and(U32.is_ge(u, 97), U32.is_le(u, 102)),
      U32.sub(u, 87),
      Bool.pick(U32, Bool.and(U32.is_ge(u, 65), U32.is_le(u, 70)),
        U32.sub(u, 55), 16))) == U32.sub(u, 55) : U32}
  %e2 : {Bool.pick(U32, _, U32.sub(u, 87),
    Bool.pick(U32, Bool.and(U32.is_ge(u, 65), U32.is_le(u, 70)),
      U32.sub(u, 55), 16)) == U32.sub(u, 55) : U32}
  %e3 : {Bool.pick(U32, _, U32.sub(u, 55), 16) == U32.sub(u, 55) : U32}
  {==}

def Laws.qs_hexval_lower(u, e1, e2):
  %e1 : {Bool.pick(U32, _, U32.sub(u, 48),
    Bool.pick(U32, Bool.and(U32.is_ge(u, 97), U32.is_le(u, 102)),
      U32.sub(u, 87),
      Bool.pick(U32, Bool.and(U32.is_ge(u, 65), U32.is_le(u, 70)),
        U32.sub(u, 55), 16))) == U32.sub(u, 87) : U32}
  %e2 : {Bool.pick(U32, _, U32.sub(u, 87),
    Bool.pick(U32, Bool.and(U32.is_ge(u, 65), U32.is_le(u, 70)),
      U32.sub(u, 55), 16)) == U32.sub(u, 87) : U32}
  {==}

def Laws.qs_hexval_none(u, e1, e2, e3):
  %e1 : {Bool.pick(U32, _, U32.sub(u, 48),
    Bool.pick(U32, Bool.and(U32.is_ge(u, 97), U32.is_le(u, 102)),
      U32.sub(u, 87),
      Bool.pick(U32, Bool.and(U32.is_ge(u, 65), U32.is_le(u, 70)),
        U32.sub(u, 55), 16))) == 16 : U32}
  %e2 : {Bool.pick(U32, _, U32.sub(u, 87),
    Bool.pick(U32, Bool.and(U32.is_ge(u, 65), U32.is_le(u, 70)),
      U32.sub(u, 55), 16)) == 16 : U32}
  %e3 : {Bool.pick(U32, _, U32.sub(u, 55), 16) == 16 : U32}
  {==}

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

def Laws.qs_qp_nil(_s, e):
  %e : {Qs.quote.plus(_) == "" : String}
  {==}

def Laws.qs_qp_space(_t):
  {==}

def Laws.qs_qp_other(cp, t, e):
  %e : {Qs.plus.one(cp, Qs.quote.plus(t), _)
    == Pct.one(False{}, cp, Qs.quote.plus(t)) : String}
  {==}

def Laws.qs_ue_nil(_ps, e):
  %e : {Qs.urlencode(_) == "" : String}
  {==}

def Laws.qs_ue_cons(_name, _value, _t):
  {==}

def Laws.qs_more_nil(_ps, e):
  %e : {Qs.form.more(_) == "" : String}
  {==}

def Laws.qs_more_cons(_name, _value, _t):
  {==}

def Laws.qs_pair(_name, _value):
  {==}

def Laws.qs_parse(_text):
  {==}

def Laws.qs_fields_nil(_ps, e):
  %e : {Qs.fields(_) == [] : List<&2, Qs.Kv()>}
  {==}

def Laws.qs_fields_skip(_t):
  {==}

def Laws.qs_fields_keep(p, t, e):
  %e : {Qs.fields.put(p, Qs.fields(t), _) == Qs.field(p) <> Qs.fields(t)
    : List<&2, Qs.Kv()>}
  {==}

def Laws.qs_field(_piece):
  {==}

def Laws.qs_field_none(_whole):
  {==}

def Laws.qs_field_some(_name, _value, _whole):
  {==}

def Laws.qs_cut_found(s, r, e):
  match s:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      ne = Equal.sym(Bool, Char.is_eq(h, '='), False{},
        eq.not.true(Char.is_eq(h, '='),
          eq.and.left(Bool.not(Char.is_eq(h, '=')), Laws.avoids(t, '='), e)))
      ih = Equal.sym(Maybe<&2, Qs.Kv()>,
        Qs.cut(String.append(t, SCon{'=', r})), Some{(t, r)},
        Laws.qs_cut_found(t, r,
          eq.and.right(Bool.not(Char.is_eq(h, '=')), Laws.avoids(t, '='), e)))
      %ne : {Qs.cut.at(h, String.append(t, SCon{'=', r}), _,
        _u => Qs.cut(String.append(t, SCon{'=', r})))
        == Some{(SCon{h, t}, r)} : Maybe<&2, Qs.Kv()>}
      %ih : {Qs.cut.push(h, _) == Some{(SCon{h, t}, r)}
        : Maybe<&2, Qs.Kv()>}
      {==}

def Laws.qs_cut_none(s, e):
  match s:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      ne = Equal.sym(Bool, Char.is_eq(h, '='), False{},
        eq.not.true(Char.is_eq(h, '='),
          eq.and.left(Bool.not(Char.is_eq(h, '=')), Laws.avoids(t, '='), e)))
      ih = Equal.sym(Maybe<&2, Qs.Kv()>, Qs.cut(t), None{},
        Laws.qs_cut_none(t,
          eq.and.right(Bool.not(Char.is_eq(h, '=')), Laws.avoids(t, '='), e)))
      %ne : {Qs.cut.at(h, t, _, _u => Qs.cut(t)) == None{}
        : Maybe<&2, Qs.Kv()>}
      %ih : {Qs.cut.push(h, _) == None{} : Maybe<&2, Qs.Kv()>}
      {==}

def Laws.qs_get_nil(_name):
  {==}

def Laws.qs_get_later(key, value, _t, name, x, e):
  %e : {Qs.get.pick(_, value, String.eq(key, name)) == Some{x}
    : Maybe<&2, String>}
  {==}

def Laws.qs_get_here(key, value, _t, name, e1, e2):
  %e1 : {Qs.get.pick(_, value, String.eq(key, name)) == Some{value}
    : Maybe<&2, String>}
  %e2 : {Qs.get.pick(None{}, value, _) == Some{value} : Maybe<&2, String>}
  {==}

def Laws.qs_get_miss(key, value, _t, name, e1, e2):
  %e1 : {Qs.get.pick(_, value, String.eq(key, name)) == None{}
    : Maybe<&2, String>}
  %e2 : {Qs.get.pick(None{}, value, _) == None{} : Maybe<&2, String>}
  {==}

# --- HTML character references (SPEC.md HTTP-REF) ---

def Laws.ref_unescape(_s):
  {==}

def Laws.ref_scan_nil(_st):
  {==}

def Laws.ref_scan_cons(_c, _t, _st):
  {==}

def Laws.ref_text_amp(c, k, e):
  %e : {Ref.text.of(c, k, _) == k(Ref.Amp{}) : String}
  {==}

def Laws.ref_text_other(c, k, e):
  %e : {Ref.text.of(c, k, _) == SCon{c, k(Ref.Txt{})} : String}
  {==}

def Laws.ref_amp_hash(c, k, e):
  %e : {Ref.amp(c, k, _) == k(Ref.Hash{}) : String}
  {==}

def Laws.ref_amp_name(c, k, e1, e2):
  %e1 : {Ref.amp(c, k, _) == k(Ref.Name{SCon{c, ""}, 1n}) : String}
  %e2 : {Ref.amp.name(c, k, _) == k(Ref.Name{SCon{c, ""}, 1n}) : String}
  {==}

def Laws.ref_amp_other(c, k, e1, e2):
  %e1 : {Ref.amp(c, k, _) == SCon{'&', Ref.step(Ref.Txt{}, c, k)} : String}
  %e2 : {Ref.amp.name(c, k, _) == SCon{'&', Ref.step(Ref.Txt{}, c, k)}
    : String}
  {==}

def Laws.ref_hash_dec(c, k, e):
  %e : {Ref.hash.dec(c, k, Ref.digit(False{}, c), _)
    == k(Ref.Num{False{}, Ref.digit(False{}, c)}) : String}
  {==}

def Laws.ref_hash_x(c, k, e1, e2):
  %e1 : {Ref.hash.dec(c, k, Ref.digit(False{}, c), _) == k(Ref.HashX{c})
    : String}
  %e2 : {Ref.hash.x(c, k, _) == k(Ref.HashX{c}) : String}
  {==}

def Laws.ref_hash_other(c, k, e1, e2):
  %e1 : {Ref.hash.dec(c, k, Ref.digit(False{}, c), _)
    == "&#" ++ Ref.step(Ref.Txt{}, c, k) : String}
  %e2 : {Ref.hash.x(c, k, _) == "&#" ++ Ref.step(Ref.Txt{}, c, k) : String}
  {==}

def Laws.ref_hashx_digit(x, c, k, e):
  %e : {Ref.hash.hex.of(x, c, k, Ref.digit(True{}, c), _)
    == k(Ref.Num{True{}, Ref.digit(True{}, c)}) : String}
  {==}

def Laws.ref_hashx_other(x, c, k, e):
  %e : {Ref.hash.hex.of(x, c, k, Ref.digit(True{}, c), _)
    == SCon{'&', SCon{'#', SCon{x, Ref.step(Ref.Txt{}, c, k)}}} : String}
  {==}

def Laws.ref_num_digit(hex, n, c, k, e):
  %e : {Ref.num(hex, n, c, k, Ref.digit(hex, c), _)
    == k(Ref.Num{hex, Ref.grow(hex, n, Ref.digit(hex, c))}) : String}
  {==}

def Laws.ref_num_semi(hex, n, c, k, e1, e2):
  %e1 : {Ref.num(hex, n, c, k, Ref.digit(hex, c), _)
    == Ref.code(n) ++ k(Ref.Txt{}) : String}
  %e2 : {Ref.num.end(n, c, k, _) == Ref.code(n) ++ k(Ref.Txt{}) : String}
  {==}

def Laws.ref_num_other(hex, n, c, k, e1, e2):
  %e1 : {Ref.num(hex, n, c, k, Ref.digit(hex, c), _)
    == Ref.code(n) ++ Ref.step(Ref.Txt{}, c, k) : String}
  %e2 : {Ref.num.end(n, c, k, _) == Ref.code(n) ++ Ref.step(Ref.Txt{}, c, k)
    : String}
  {==}

def Laws.ref_name_semi(s, len, c, k, e):
  %e : {Ref.name(s, len, c, k, _) == Ref.named(s ++ ";") ++ k(Ref.Txt{})
    : String}
  {==}

def Laws.ref_name_join(s, len, c, k, e1, e2):
  %e1 : {Ref.name(s, len, c, k, _)
    == k(Ref.Name{s ++ SCon{c, ""}, 1n+len}) : String}
  %e2 : {Ref.name.more(s, len, c, k, _)
    == k(Ref.Name{s ++ SCon{c, ""}, 1n+len}) : String}
  {==}

def Laws.ref_name_stop(s, len, c, k, e1, e2):
  %e1 : {Ref.name(s, len, c, k, _)
    == Ref.named(s) ++ Ref.step(Ref.Txt{}, c, k) : String}
  %e2 : {Ref.name.more(s, len, c, k, _)
    == Ref.named(s) ++ Ref.step(Ref.Txt{}, c, k) : String}
  {==}

def Laws.ref_end_text(_st, e):
  %e : {Ref.end(_) == "" : String}
  {==}

def Laws.ref_end_amp(_st, e):
  %e : {Ref.end(_) == "&" : String}
  {==}

def Laws.ref_end_hash(_st, e):
  %e : {Ref.end(_) == "&#" : String}
  {==}

def Laws.ref_end_hashx(_x):
  {==}

def Laws.ref_end_num(_hex, _n):
  {==}

def Laws.ref_end_name(_s, _len):
  {==}

def Laws.ref_name_char(_c):
  {==}

def Laws.ref_digit_dec(u, e):
  %e : {Bool.pick(U32, _, U32.sub(u, 48), 16) == U32.sub(u, 48) : U32}
  {==}

def Laws.ref_digit_dec_none(u, e):
  %e : {Bool.pick(U32, _, U32.sub(u, 48), 16) == 16 : U32}
  {==}

def Laws.ref_digit_hex_dec(u, e):
  %e : {Bool.pick(U32, _, U32.sub(u, 48),
    Bool.pick(U32, Bool.and(U32.is_le(65, u), U32.is_le(u, 70)),
      U32.sub(u, 55),
      Bool.pick(U32, Bool.and(U32.is_le(97, u), U32.is_le(u, 102)),
        U32.sub(u, 87), 16))) == U32.sub(u, 48) : U32}
  {==}

def Laws.ref_digit_hex_upper(u, e1, e2):
  %e1 : {Bool.pick(U32, _, U32.sub(u, 48),
    Bool.pick(U32, Bool.and(U32.is_le(65, u), U32.is_le(u, 70)),
      U32.sub(u, 55),
      Bool.pick(U32, Bool.and(U32.is_le(97, u), U32.is_le(u, 102)),
        U32.sub(u, 87), 16))) == U32.sub(u, 55) : U32}
  %e2 : {Bool.pick(U32, _, U32.sub(u, 55),
    Bool.pick(U32, Bool.and(U32.is_le(97, u), U32.is_le(u, 102)),
      U32.sub(u, 87), 16)) == U32.sub(u, 55) : U32}
  {==}

def Laws.ref_digit_hex_lower(u, e1, e2, e3):
  %e1 : {Bool.pick(U32, _, U32.sub(u, 48),
    Bool.pick(U32, Bool.and(U32.is_le(65, u), U32.is_le(u, 70)),
      U32.sub(u, 55),
      Bool.pick(U32, Bool.and(U32.is_le(97, u), U32.is_le(u, 102)),
        U32.sub(u, 87), 16))) == U32.sub(u, 87) : U32}
  %e2 : {Bool.pick(U32, _, U32.sub(u, 55),
    Bool.pick(U32, Bool.and(U32.is_le(97, u), U32.is_le(u, 102)),
      U32.sub(u, 87), 16)) == U32.sub(u, 87) : U32}
  %e3 : {Bool.pick(U32, _, U32.sub(u, 87), 16) == U32.sub(u, 87) : U32}
  {==}

def Laws.ref_digit_hex_none(u, e1, e2, e3):
  %e1 : {Bool.pick(U32, _, U32.sub(u, 48),
    Bool.pick(U32, Bool.and(U32.is_le(65, u), U32.is_le(u, 70)),
      U32.sub(u, 55),
      Bool.pick(U32, Bool.and(U32.is_le(97, u), U32.is_le(u, 102)),
        U32.sub(u, 87), 16))) == 16 : U32}
  %e2 : {Bool.pick(U32, _, U32.sub(u, 55),
    Bool.pick(U32, Bool.and(U32.is_le(97, u), U32.is_le(u, 102)),
      U32.sub(u, 87), 16)) == 16 : U32}
  %e3 : {Bool.pick(U32, _, U32.sub(u, 87), 16) == 16 : U32}
  {==}

def Laws.ref_grow(_hex, _n, _d):
  {==}

def Laws.ref_code(_n):
  {==}

def Laws.ref_code_zero(n, e):
  %e : {Ref.code.zero(n, _) == SCon{Chr{65533}, ""} : String}
  {==}

def Laws.ref_code_cr(n, e1, e2):
  %e1 : {Ref.code.zero(n, _) == "\r" : String}
  %e2 : {Ref.code.cr(n, _) == "\r" : String}
  {==}

def Laws.ref_code_c1(n, e1, e2, e3):
  %e1 : {Ref.code.zero(n, _)
    == SCon{Chr{Ref.nth(Ref.w1252(), U32.to_nat(U32.sub(n, 128)))}, ""}
    : String}
  %e2 : {Ref.code.cr(n, _)
    == SCon{Chr{Ref.nth(Ref.w1252(), U32.to_nat(U32.sub(n, 128)))}, ""}
    : String}
  %e3 : {Ref.code.c1(n, _)
    == SCon{Chr{Ref.nth(Ref.w1252(), U32.to_nat(U32.sub(n, 128)))}, ""}
    : String}
  {==}

def Laws.ref_code_bad(n, e1, e2, e3, e4):
  %e1 : {Ref.code.zero(n, _) == SCon{Chr{65533}, ""} : String}
  %e2 : {Ref.code.cr(n, _) == SCon{Chr{65533}, ""} : String}
  %e3 : {Ref.code.c1(n, _) == SCon{Chr{65533}, ""} : String}
  %e4 : {Ref.code.range(n, _) == SCon{Chr{65533}, ""} : String}
  {==}

def Laws.ref_code_dropped(n, e1, e2, e3, e4, e5):
  %e1 : {Ref.code.zero(n, _) == "" : String}
  %e2 : {Ref.code.cr(n, _) == "" : String}
  %e3 : {Ref.code.c1(n, _) == "" : String}
  %e4 : {Ref.code.range(n, _) == "" : String}
  %e5 : {Ref.code.kept(n, _) == "" : String}
  {==}

def Laws.ref_code_kept(n, e1, e2, e3, e4, e5):
  %e1 : {Ref.code.zero(n, _) == SCon{Chr{n}, ""} : String}
  %e2 : {Ref.code.cr(n, _) == SCon{Chr{n}, ""} : String}
  %e3 : {Ref.code.c1(n, _) == SCon{Chr{n}, ""} : String}
  %e4 : {Ref.code.range(n, _) == SCon{Chr{n}, ""} : String}
  %e5 : {Ref.code.kept(n, _) == SCon{Chr{n}, ""} : String}
  {==}

def Laws.ref_dropped(_n):
  {==}

def Laws.ref_named(_s):
  {==}

def Laws.ref_named_none(_s):
  {==}

def Laws.ref_named_some(_name, _first, _second, _s):
  {==}

def Laws.ref_best_nil(_s, _sofar):
  {==}

def Laws.ref_best_cons(_r, _t, _s, _sofar):
  {==}

def Laws.ref_step(_sofar, _name, _first, _second, _s):
  {==}

def Laws.ref_hit_miss(_sofar, _r, _name):
  {==}

def Laws.ref_hit_take(_sofar, _r, _name):
  {==}

def Laws.ref_take_longer(_sofar, _r):
  {==}

def Laws.ref_take_keep(_sofar, _r):
  {==}

def Laws.ref_len_none(_m, e):
  %e : {Ref.best.len(_) == 0n : Nat}
  {==}

def Laws.ref_len_some(_name, _first, _second):
  {==}

def Laws.ref_chars_one(first, second, e):
  %e : {SCon{Chr{first}, Bool.pick(String, _, "", SCon{Chr{second}, ""})}
    == SCon{Chr{first}, ""} : String}
  {==}

def Laws.ref_chars_two(first, second, e):
  %e : {SCon{Chr{first}, Bool.pick(String, _, "", SCon{Chr{second}, ""})}
    == SCon{Chr{first}, SCon{Chr{second}, ""}} : String}
  {==}

# --- cookies sent back (SPEC.md HTTP-CK) ---

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

def Laws.ck_echo(_lines):
  {==}

def Laws.ck_store_nil(_jar):
  {==}

def Laws.ck_store_cons(_l, _t, _jar):
  {==}

def Laws.ck_add_none(_jar):
  {==}

def Laws.ck_add_some(_jar, _name, _value):
  {==}

def Laws.ck_put_nil(_name, _value):
  {==}

def Laws.ck_put_hit(key, old, t, name, value, e):
  %e : {Echo.put.at(key, old, value, t, _, _u => Echo.put(t, name, value))
    == (key, value) <> t : List<&2, Qs.Kv()>}
  {==}

def Laws.ck_put_miss(key, old, t, name, value, e):
  %e : {Echo.put.at(key, old, value, t, _, _u => Echo.put(t, name, value))
    == (key, old) <> Echo.put(t, name, value) : List<&2, Qs.Kv()>}
  {==}

def Laws.ck_line_nil(_jar, e):
  %e : {Echo.line(_) == "" : String}
  {==}

def Laws.ck_line_cons(_name, _value, _t):
  {==}

def Laws.ck_more_nil(_jar, e):
  %e : {Echo.more(_) == "" : String}
  {==}

def Laws.ck_more_cons(_name, _value, _t):
  {==}

def Laws.ck_one(_name, _value):
  {==}

def Laws.ck_values_nil(_hs, e):
  %e : {Echo.values(_) == [] : List<&2, String>}
  {==}

def Laws.ck_values_hit(_name, value, t, e):
  %e : {Echo.values.put(value, Echo.values(t), _) == value <> Echo.values(t)
    : List<&2, String>}
  {==}

def Laws.ck_values_miss(_name, value, t, e):
  %e : {Echo.values.put(value, Echo.values(t), _) == Echo.values(t)
    : List<&2, String>}
  {==}

# --- unescape after escape (SPEC.md HTTP-REF-4) ---

# what a comparison that is not EQ cannot equal
def eq.cmp.emp(c: Cmp) -> Type:
  match c:
    case LT{}:
      Unit
    case EQ{}:
      Empty
    case GT{}:
      Unit

def eq.cmp.lt(e: {LT{} == EQ{} : Cmp}) -> Empty:
  %e : eq.cmp.emp(_)
  Unit{}

def eq.cmp.gt(e: {GT{} == EQ{} : Cmp}) -> Empty:
  %e : eq.cmp.emp(_)
  Unit{}

def eq.bool_cmp_eq(a: Bool, b: Bool, e: {Bool.cmp(a, b) == EQ{} : Cmp})
  -> {a == b : Bool}:
  match a b:
    case False{} False{}:
      {==}
    case False{} True{}:
      eq.bit.gone(&2, {False{} == True{} : Bool}, eq.cmp.lt(e))
    case True{} False{}:
      eq.bit.gone(&2, {True{} == False{} : Bool}, eq.cmp.gt(e))
    case True{} True{}:
      {==}

def eq.fin.t(ab: Bool, bb: Bool, t: Cmp,
  e: {Word.cmp.fin(ab, bb, t) == EQ{} : Cmp}) -> {t == EQ{} : Cmp}:
  match t:
    case LT{}:
      eq.bit.gone(&2, {LT{} == EQ{} : Cmp}, eq.cmp.lt(e))
    case EQ{}:
      {==}
    case GT{}:
      eq.bit.gone(&2, {GT{} == EQ{} : Cmp}, eq.cmp.gt(e))

def eq.fin.b(ab: Bool, bb: Bool, t: Cmp,
  e: {Word.cmp.fin(ab, bb, t) == EQ{} : Cmp}) -> {Bool.cmp(ab, bb) == EQ{} : Cmp}:
  match t:
    case LT{}:
      eq.bit.gone(&2, {Bool.cmp(ab, bb) == EQ{} : Cmp}, eq.cmp.lt(e))
    case EQ{}:
      e
    case GT{}:
      eq.bit.gone(&2, {Bool.cmp(ab, bb) == EQ{} : Cmp}, eq.cmp.gt(e))

def eq.word_cmp_eq(n: Nat, a: Word(n), b: Word(n),
  +e: {Word.cmp(n, a, b) == EQ{} : Cmp}) -> {a == b : Word(n)}:
  match n:
    case 0n:
      match a b:
        case WNil{} WNil{}:
          {==}
    case 1n+(+p):
      match a b:
        case WCon{+ab, +at} WCon{+bb, +bt}:
          be = eq.bool_cmp_eq(ab, bb, eq.fin.b(ab, bb, Word.cmp(p, at, bt), e))
          we = eq.word_cmp_eq(p, at, bt, eq.fin.t(ab, bb, Word.cmp(p, at, bt), e))
          %be : {WCon{ab, at} == WCon{_, bt} : Word(1n+p)}
          %we : {WCon{ab, at} == WCon{ab, _} : Word(1n+p)}
          {==}

def eq.cmp_is_eq(t: Cmp, e: {Cmp.is_eq(t) == True{} : Bool})
  -> {t == EQ{} : Cmp}:
  match t:
    case LT{}:
      eq.bit.absurd(&2, {LT{} == EQ{} : Cmp}, e)
    case EQ{}:
      {==}
    case GT{}:
      eq.bit.absurd(&2, {GT{} == EQ{} : Cmp}, e)

def eq.char_eq_true(c: Char, d: Char, e: {Char.is_eq(c, d) == True{} : Bool})
  -> {c == d : Char}:
  match c d:
    case Chr{U32{+w}} Chr{U32{+v}}:
      we = eq.word_cmp_eq(32n, w, v, eq.cmp_is_eq(Word.cmp(32n, w, v), e))
      %we : {Chr{U32{w}} == Chr{U32{_}} : Char}
      {==}

# a character that is not `&`, `<`, `>`, `"` or `'` scans as itself
def rt.other(+c: Char, x: String, e: {False{} == Char.is_eq(c, '&') : Bool})
  -> {Ref.scan(SCon{c, x}, Ref.Txt{}) == SCon{c, Ref.scan(x, Ref.Txt{})}
    : String}:
  %e : {Ref.text.of(c, st2 => Ref.scan(x, st2), _)
    == SCon{c, Ref.scan(x, Ref.Txt{})} : String}
  {==}

def rt.sq(+c: Char, x: String, ea: {False{} == Char.is_eq(c, '&') : Bool},
  b: Bool, e: {Char.is_eq(c, '\'') == b : Bool})
  -> {Ref.scan(Html.one.sq(c, x, b), Ref.Txt{})
    == SCon{c, Ref.scan(x, Ref.Txt{})} : String}:
  match b:
    case True{}:
      ce = Equal.sym(Char, c, '\'', eq.char_eq_true(c, '\'', e))
      %ce : {Ref.scan("&#39;" ++ x, Ref.Txt{})
        == SCon{_, Ref.scan(x, Ref.Txt{})} : String}
      {==}
    case False{}:
      rt.other(c, x, ea)

def rt.dq(+c: Char, x: String, ea: {False{} == Char.is_eq(c, '&') : Bool},
  b: Bool, e: {Char.is_eq(c, '"') == b : Bool})
  -> {Ref.scan(Html.one.dq(c, x, b), Ref.Txt{})
    == SCon{c, Ref.scan(x, Ref.Txt{})} : String}:
  match b:
    case True{}:
      ce = Equal.sym(Char, c, '"', eq.char_eq_true(c, '"', e))
      %ce : {Ref.scan("&#34;" ++ x, Ref.Txt{})
        == SCon{_, Ref.scan(x, Ref.Txt{})} : String}
      {==}
    case False{}:
      rt.sq(c, x, ea, Char.is_eq(c, '\''), {==})

def rt.gt(+c: Char, x: String, ea: {False{} == Char.is_eq(c, '&') : Bool},
  b: Bool, e: {Char.is_eq(c, '>') == b : Bool})
  -> {Ref.scan(Html.one.gt(c, x, b), Ref.Txt{})
    == SCon{c, Ref.scan(x, Ref.Txt{})} : String}:
  match b:
    case True{}:
      ce = Equal.sym(Char, c, '>', eq.char_eq_true(c, '>', e))
      %ce : {Ref.scan("&gt;" ++ x, Ref.Txt{})
        == SCon{_, Ref.scan(x, Ref.Txt{})} : String}
      {==}
    case False{}:
      rt.dq(c, x, ea, Char.is_eq(c, '"'), {==})

def rt.lt(+c: Char, x: String, ea: {False{} == Char.is_eq(c, '&') : Bool},
  b: Bool, e: {Char.is_eq(c, '<') == b : Bool})
  -> {Ref.scan(Html.one.lt(c, x, b), Ref.Txt{})
    == SCon{c, Ref.scan(x, Ref.Txt{})} : String}:
  match b:
    case True{}:
      ce = Equal.sym(Char, c, '<', eq.char_eq_true(c, '<', e))
      %ce : {Ref.scan("&lt;" ++ x, Ref.Txt{})
        == SCon{_, Ref.scan(x, Ref.Txt{})} : String}
      {==}
    case False{}:
      rt.gt(c, x, ea, Char.is_eq(c, '>'), {==})

def rt.amp(+c: Char, x: String, b: Bool, e: {Char.is_eq(c, '&') == b : Bool})
  -> {Ref.scan(Html.one.amp(c, x, b), Ref.Txt{})
    == SCon{c, Ref.scan(x, Ref.Txt{})} : String}:
  match b:
    case True{}:
      ce = Equal.sym(Char, c, '&', eq.char_eq_true(c, '&', e))
      %ce : {Ref.scan("&amp;" ++ x, Ref.Txt{})
        == SCon{_, Ref.scan(x, Ref.Txt{})} : String}
      {==}
    case False{}:
      rt.lt(c, x, Equal.sym(Bool, Char.is_eq(c, '&'), False{}, e),
        Char.is_eq(c, '<'), {==})

def rt.go(s: String)
  -> {Ref.scan(Html.escape.onto(s, ""), Ref.Txt{}) == s : String}:
  match s:
    case SNil{}:
      {==}
    case SCon{+c, +t}:
      Equal.trans(String,
        Ref.scan(Html.one(c, Html.escape.onto(t, "")), Ref.Txt{}),
        SCon{c, Ref.scan(Html.escape.onto(t, ""), Ref.Txt{})},
        SCon{c, t},
        rt.amp(c, Html.escape.onto(t, ""), Char.is_eq(c, '&'), {==}),
        Equal.cong(String, String, y => SCon{c, y},
          Ref.scan(Html.escape.onto(t, ""), Ref.Txt{}), t, rt.go(t)))

def Laws.ref_round(s):
  rt.go(s)

# fresh_no_store_any: fresh matches no-store first
def Laws.fresh_no_store_any(
  _no_cache,
  _public,
  _private,
  _max_age,
  _expires,
  _age
):
  {==}

# fresh_no_cache_any: no-store either way, then no-cache
def Laws.fresh_no_cache_any(
  no_store,
  _public,
  _private,
  _max_age,
  _expires,
  _age
):
  match no_store:
    case False{}:
      {==}
    case True{}:
      {==}

# cookie_age_sets holds by unfolding cookie.age
def Laws.cookie_age_sets(
  _name,
  _value,
  _expires,
  _max_age,
  _domain,
  _path,
  _secure,
  _http_only,
  _same_site,
  _host_only,
  _age
):
  {==}

# cors_preflight_bad: preflight_req matches the request first
def Laws.cors_preflight_bad(_cfg, _why):
  {==}

# b64_go_end: go matches the input first
def Laws.b64_go_end(_phase):
  {==}

# --- the client's deadline and failures (SPEC.md HTTP-CLI-1, 2, 13, 14) ---

def Laws.ms_none(_m, e):
  %e : {Spec.wire.ms.of(_) == 60000 : U32}
  {==}

def Laws.ms_given(ms, e):
  %e : {Spec.wire.ms.pick(ms, _) == ms : U32}
  {==}

def Laws.ms_zero(ms, e):
  %e : {Spec.wire.ms.pick(ms, _) == 1 : U32}
  {==}

# a resolve's failure is fail.resolve, ran out of time or not
def fail.resolve.any(host: String, +port: U32, +ms: U32, +n: U32, why: String,
  late: Bool)
  -> {Spec.wire.fail.of(Spec.Resolve{}, host, port, ms, n, why, late)
    == Spec.wire.fail.resolve(host, n, U32.is_eq(n, 2)) : String}:
  match late:
    case True{}:
      {==}
    case False{}:
      {==}

# a resolve that failed with another number names the cause
def fail.resolve.some(host: String, +n: U32,
  e: {False{} == U32.is_eq(n, 2) : Bool})
  -> {Spec.wire.fail.resolve(host, n, U32.is_eq(n, 2))
    == "6\ncould not resolve " ++ host ++ ": " ++ Spec.wire.cause(n)
    : String}:
  %e : {Spec.wire.fail.resolve(host, n, _)
    == "6\ncould not resolve " ++ host ++ ": " ++ Spec.wire.cause(n)
    : String}
  {==}

# a name with no address names the host alone
def fail.resolve.none(host: String, +n: U32,
  e: {True{} == U32.is_eq(n, 2) : Bool})
  -> {Spec.wire.fail.resolve(host, n, U32.is_eq(n, 2))
    == "6\ncould not resolve " ++ host : String}:
  %e : {Spec.wire.fail.resolve(host, n, _) == "6\ncould not resolve " ++ host
    : String}
  {==}

def Laws.fail_resolve(host, port, ms, n, e, why):
  Equal.trans(String,
    Spec.wire.fail(Spec.Resolve{}, host, port, ms, n, why),
    Spec.wire.fail.resolve(host, n, U32.is_eq(n, 2)),
    "6\ncould not resolve " ++ host ++ ": " ++ Spec.wire.cause(n),
    fail.resolve.any(host, port, ms, n, why, U32.is_eq(n, 110)),
    fail.resolve.some(host, n, e))

def Laws.fail_resolve_none(host, port, ms, n, e, why):
  Equal.trans(String,
    Spec.wire.fail(Spec.Resolve{}, host, port, ms, n, why),
    Spec.wire.fail.resolve(host, n, U32.is_eq(n, 2)),
    "6\ncould not resolve " ++ host,
    fail.resolve.any(host, port, ms, n, why, U32.is_eq(n, 110)),
    fail.resolve.none(host, n, e))

# a call that ran out of time is reported by fail.late
def fail.at.late(p: Spec.Phase, host: String, +port: U32, +ms: U32, +n: U32,
  why: String, e: {True{} == U32.is_eq(n, 110) : Bool})
  -> {Spec.wire.fail(p, host, port, ms, n, why)
    == Spec.wire.fail.late(p, host, port, ms, n) : String}:
  %e : {Spec.wire.fail.of(p, host, port, ms, n, why, _)
    == Spec.wire.fail.late(p, host, port, ms, n) : String}
  {==}

# a call that failed otherwise is reported by fail.other
def fail.at.other(p: Spec.Phase, host: String, +port: U32, +ms: U32, +n: U32,
  why: String, e: {False{} == U32.is_eq(n, 110) : Bool})
  -> {Spec.wire.fail(p, host, port, ms, n, why)
    == Spec.wire.fail.other(p, host, port, n, why) : String}:
  %e : {Spec.wire.fail.of(p, host, port, ms, n, why, _)
    == Spec.wire.fail.other(p, host, port, n, why) : String}
  {==}

def Laws.fail_connect_late(host, port, ms, n, e, why):
  fail.at.late(Spec.Connect{}, host, port, ms, n, why, e)

def Laws.fail_handshake_late(host, port, ms, n, e, why):
  fail.at.late(Spec.Handshake{}, host, port, ms, n, why, e)

def Laws.fail_send_late(host, port, ms, n, e, why):
  fail.at.late(Spec.Send{}, host, port, ms, n, why, e)

def Laws.fail_receive_late(host, port, ms, n, e, why):
  fail.at.late(Spec.Receive{}, host, port, ms, n, why, e)

def Laws.fail_connect(host, port, ms, n, e, why):
  fail.at.other(Spec.Connect{}, host, port, ms, n, why, e)

def Laws.fail_handshake(host, port, ms, n, e, why):
  fail.at.other(Spec.Handshake{}, host, port, ms, n, why, e)

def Laws.fail_send(host, port, ms, n, e, why):
  fail.at.other(Spec.Send{}, host, port, ms, n, why, e)

def Laws.fail_receive(host, port, ms, n, e, why):
  fail.at.other(Spec.Receive{}, host, port, ms, n, why, e)

def Laws.cause_is(_n):
  {==}

def Laws.errno_names(_n):
  {==}

def Laws.errno_or_none(s, e):
  match s:
    case SNil{}:
      {==}
    case SCon{h, t}:
      eq.bit.absurd(&2, {Spec.wire.errno.or(SCon{h, t}) == "errno" : String},
        Equal.sym(Bool, True{}, False{}, e))

def Laws.errno_or_named(s, e):
  match s:
    case SNil{}:
      eq.bit.absurd(&2, {Spec.wire.errno.or(SNil{}) == SNil{} : String}, e)
    case SCon{h, t}:
      {==}

# --- what is sent (SPEC.md HTTP-CLI-10) ---

def Laws.payload_nil(_rest):
  {==}

def Laws.payload_cons(_cp, _t, _rest):
  {==}

# --- octets after a prefix (SPEC.md HTTP-BODY-2, 3) ---

# the first |b| characters of b ++ r are b
def take_prefix(b: String, r: String)
  -> {String.take(String.append(b, r), String.length(b)) == b : String}:
  match b:
    case SNil{}:
      match r:
        case SNil{}:
          {==}
        case SCon{h, t}:
          {==}
    case SCon{h, t}:
      Equal.cong(String, String, x => SCon{h, x},
        String.take(String.append(t, r), String.length(t)), t,
        take_prefix(t, r))

# what follows |b| + k characters of b ++ r is what follows k of r
def drop_prefix(b: String, r: String, k: Nat)
  -> {String.drop(String.append(b, r), Nat.add(String.length(b), k))
    == String.drop(r, k) : String}:
  match b:
    case SNil{}:
      {==}
    case SCon{h, t}:
      drop_prefix(t, r, k)

# b ++ r is never shorter than b
def lt_prefix(b: String, r: String)
  -> {Nat.is_lt(String.length(String.append(b, r)), String.length(b))
    == False{} : Bool}:
  match b:
    case SNil{}:
      match r:
        case SNil{}:
          {==}
        case SCon{h, t}:
          {==}
    case SCon{h, t}:
      lt_prefix(t, r)

def Laws.octs_len(s):
  match s:
    case SNil{}:
      {==}
    case SCon{h, t}:
      Equal.cong(Nat, Nat, x => 1n+x, Http.octs.len(t), String.length(t),
        Laws.octs_len(t))


def Laws.octs_take(s, n):
  match s:
    case SNil{}:
      {==}
    case SCon{h, t}:
      match n:
        case 0n:
          {==}
        case 1n+k:
          match k:
            case 0n:
              Equal.cong(String, String, x => SCon{h, x}, Http.octs.take(t, 0n),
                String.take(t, 0n), Laws.octs_take(t, 0n))
            case 1n+j:
              Equal.cong(String, String, x => SCon{h, x},
                Http.octs.take(t, 1n+j), String.take(t, 1n+j),
                Laws.octs_take(t, 1n+j))


def Laws.octs_drop(s, n):
  match s:
    case SNil{}:
      {==}
    case SCon{h, t}:
      match n:
        case 0n:
          {==}
        case 1n+k:
          match k:
            case 0n:
              Laws.octs_drop(t, 0n)
            case 1n+j:
              Laws.octs_drop(t, 1n+j)


def Laws.clen_prefix(st, hs, b, r):
  +br = String.append(b, r)
  +n = String.length(b)
  %Equal.sym(Nat, Http.octs.len(br), String.length(br), Laws.octs_len(br))
    : {Http.parse.short(st, hs, n, br, Nat.is_lt(_, n))
      == Http.Reply{st, hs, b} : Http.Reply}
  %Equal.sym(Bool, Nat.is_lt(String.length(br), n), False{}, lt_prefix(b, r))
    : {Http.parse.short(st, hs, n, br, _) == Http.Reply{st, hs, b}
      : Http.Reply}
  %Equal.sym(String, Http.octs.take(br, n), String.take(br, n),
    Laws.octs_take(br, n))
    : {Http.Reply{st, hs, _} == Http.Reply{st, hs, b} : Http.Reply}
  %Equal.sym(String, String.take(br, n), b, take_prefix(b, r))
    : {Http.Reply{st, hs, _} == Http.Reply{st, hs, b} : Http.Reply}
  {==}


def Laws.chunk_data(f, h, d, r, e, el):
  +a = String.append(d, "\r\n" ++ r)
  +rhs = String.append(d, Http.chunks(f, Http.divide(r, "\r\n")))
  %e : {Http.chunks.more(Http.hexlen(h), a,
    _u => Http.chunks(f, Http.divide(Http.octs.drop(a,
      Nat.add(Http.hexlen(h), 2n)), "\r\n")), _) == rhs : String}
  %el : {String.append(Http.octs.take(a, _),
    Http.chunks(f, Http.divide(Http.octs.drop(a, Nat.add(_, 2n)), "\r\n")))
    == rhs : String}
  +n = String.length(d)
  %Equal.sym(String, Http.octs.take(a, n), String.take(a, n),
    Laws.octs_take(a, n))
    : {String.append(_, Http.chunks(f, Http.divide(Http.octs.drop(a,
      Nat.add(n, 2n)), "\r\n"))) == rhs : String}
  %Equal.sym(String, String.take(a, n), d, take_prefix(d, "\r\n" ++ r))
    : {String.append(_, Http.chunks(f, Http.divide(Http.octs.drop(a,
      Nat.add(n, 2n)), "\r\n"))) == rhs : String}
  %Equal.sym(String, Http.octs.drop(a, Nat.add(n, 2n)),
    String.drop(a, Nat.add(n, 2n)), Laws.octs_drop(a, Nat.add(n, 2n)))
    : {String.append(d, Http.chunks(f, Http.divide(_, "\r\n"))) == rhs
      : String}
  %Equal.sym(String, String.drop(a, Nat.add(n, 2n)), r,
    Equal.trans(String, String.drop(a, Nat.add(n, 2n)), String.drop(r, 0n), r,
      drop_prefix(d, "\r\n" ++ r, 2n), eq.drop_zero(r)))
    : {String.append(d, Http.chunks(f, Http.divide(_, "\r\n"))) == rhs
      : String}
  {==}

def Laws.chunk_last(_f, h, after, e):
  %e : {Http.chunks.more(Http.hexlen(h), after,
    _u => Http.chunks(_f, Http.divide(Http.octs.drop(after,
      Nat.add(Http.hexlen(h), 2n)), "\r\n")), _) == "" : String}
  {==}


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


def Laws.step_text(_method, _target, _hs, _body):
  {==}

def Laws.step_text_bad(_why):
  {==}

def Laws.hit_field(_b, _name, _value):
  {==}

def Laws.hit_file(_b, _name, _filename, _ctype, _clash):
  {==}

def Laws.payload_is(_req):
  {==}


# proofs of laws/ExchangeCarriesMethod.bend
import Base
import ../src/http.bend as Http
import ../laws/ExchangeCarriesMethod.bend as Laws
import ./lemmas/BaseEqualities.bend as M1

# --- the request's header fields ---

# a string prefix both sides share does not change starts_with
def eq.starts_cancel(+a: String, +x: String, +y: String)
  -> {String.starts_with.go(String.append(a, y), String.append(a, x))
    == String.starts_with.go(y, x) : Bool}:
  match a:
    case SNil{}:
      {==}
    case SCon{h, t}:
      %Equal.sym(Bool, Char.is_eq(h, h), True{}, M1.eq.char_eq_self(h))
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

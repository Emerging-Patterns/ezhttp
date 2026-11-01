# proofs of laws/RequestLineAndHost.bend
import Base
import ../src/http.bend as Http
import ../laws/RequestLineAndHost.bend as Laws

# --- the client's requests ---

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

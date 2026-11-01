import Base
import ../src/http.bend as Http
import ../src/cors.bend as Cors

# LAW: a preflight for a request that did not parse is 400 with its reason,
# whatever the allow-list
law cors_preflight_bad:
  for cfg: Cors.Cfg
  for why: String
  {Cors.cors.preflight_req(cfg, Http.Bad{why}) == Http.Reply{400, [], why}
    : Http.Reply}

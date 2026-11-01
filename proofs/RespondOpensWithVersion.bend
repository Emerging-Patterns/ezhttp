# proofs of laws/RespondOpensWithVersion.bend
import Base
import ../src/http.bend as Http
import ../laws/RespondOpensWithVersion.bend as Laws
import ./lemmas/BaseEqualities.bend as M1

def Laws.respond_opens_with_version(status, hs, body):
  M1.eq.starts_append("HTTP/1.1 ",
    U32.show(status) ++ " " ++ Http.reason(status) ++ "\r\n"
      ++ "Connection: close\r\n" ++ Http.headers.lines(hs)
      ++ Http.clen.line(Http.utf8.len(body), Nat.is_eq(Http.utf8.len(body), 0n))
      ++ "\r\n" ++ body)

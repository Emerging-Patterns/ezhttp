# ezhttp/src/step: what the server decides for one connection, kept pure so
# a law can state it. server.bend runs the effects and asks this module what
# each outcome means; it decides nothing itself.
import Base
import ./http.bend as Http
import ./qs.bend as Qs

# what a request asks of the server: answer it now, or call the handler
type Step is Data:
  Answer{reply: Http.Reply}
  Call{req: Http.Request}

# an effect's outcome on one connection: the value, or the line to log for
# a connection that is lost
type Got<-A: Type> is Type:
  Kept{value: A}
  Lost{line: String}

# a request received as octets, as text: its method, target, header names
# and values and body each decoded as UTF-8 (SPEC.md HTTP-SRV-2); a bad one
# keeps its reason
def step.text(req: Http.Request) -> Http.Request:
  match req:
    case Http.Bad{why}:
      Http.Bad{why}
    case Http.Request{method, target, headers, body}:
      Http.Request{Qs.octets.text(method), Qs.octets.text(target),
        Qs.octets.headers(headers), Qs.octets.text(body)}

# a bad request is answered 400 with its reason and never reaches the
# handler; a good one goes to the handler as it was parsed
def step.of(req: Http.Request) -> Step:
  match req:
    case Http.Bad{why}:
      Answer{Http.Reply{400, [], why}}
    case Http.Request{method, target, headers, body}:
      Call{Http.Request{method, target, headers, body}}

# the line logged for a failed effect: `ezhttp: <phase>: <why>`
def step.line(phase: String, why: String) -> String:
  "ezhttp: " ++ phase ++ ": " ++ why

# a failed accept or recv loses the connection instead of ending the server
def step.got(
  -A: Type,
  phase: String,
  res: Result<&1, &1, U32 & String, A>
) -> Got<A>:
  match res:
    case Fail{(code, why)}:
      Lost{step.line(phase, why)}
    case Done{value}:
      Kept{value}

# a failed send loses the connection too; the bytes it did not send are dropped
def step.sent(res: Result<&1, &1, (U32 & String) & List<&2, U32>, Unit>)
  -> Got<Unit>:
  match res:
    case Fail{((code, why), left)}:
      Lost{step.line("write", why)}
    case Done{value}:
      Kept{value}

# --- the replies and the handler's request (SPEC.md HTTP-SRV-8, 9) ---

# whether a reply is written with its head only: a reply to HEAD, or a 204
# or 304 (RFC 9110 §9.3.2, §15.3.5, §15.4.5)
def step.bare(+method: String, +status: U32) -> Bool:
  Bool.or(String.eq(method, "HEAD"), Http.status.nocontent(status))

# the body octets of a request, as they arrived; none for a bad one
def step.octets(req: Http.Request) -> String:
  match req:
    case Http.Bad{why}:
      ""
    case Http.Request{method, target, headers, body}:
      body

# what an accept with a deadline brought: a connection, nothing before the
# deadline, or a lost accept with its line (SPEC.md HTTP-SRV-4)
type Accept<-A: Type> is Type:
  Took{value: A}
  Idle{}
  Missed{line: String}

# a failed accept once it is known whether its deadline passed
def step.missed(-A: Type, +why: String, late: Bool) -> Accept<A>:
  match late:
    case True{}:
      Idle{}
    case False{}:
      Missed{step.line("accept", why)}

# an accept's outcome: ETIMEDOUT (110) is a deadline that passed
def step.accepted(-A: Type, res: Result<&1, &1, U32 & String, A>)
  -> Accept<A>:
  match res:
    case Fail{(+code, why)}:
      step.missed(A, why, U32.is_eq(code, 110))
    case Done{value}:
      Took{value}

# --- when a request has all arrived (SPEC.md HTTP-TRUST-2) ---

# a Content-Length that reads, or none
def step.clen(m: Maybe<&2, Nat>) -> Nat:
  match m:
    case None{}:
      0n
    case Some{n}:
      n

# octets a request needs in all once its head has ended: the head, its blank
# line and the octets its Content-Length names (0 when it names none)
def step.need.of(c: Http.Cut) -> Maybe<&2, Nat>:
  match c:
    case Http.NoCut{}:
      None{}
    case Http.Cut{+before, after}:
      Some{Nat.add(Nat.add(String.length(before), 4n),
        step.clen(Http.digits.read(Http.first(
          Http.head.values(String.lines(before), "content-length")))))}

# octets a request needs in all, none while its head has not ended
def step.need(+text: String) -> Maybe<&2, Nat>:
  step.need.of(Http.divide(text, "\r\n\r\n"))

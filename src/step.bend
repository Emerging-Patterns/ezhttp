# ezhttp/src/step: what the server decides for one connection, kept pure so
# a law can state it. server.bend runs the effects and asks this module what
# each outcome means; it decides nothing itself.
import Base
import ./http.bend as Http

# what a request asks of the server: answer it now, or call the handler
type Step is Data:
  Answer{reply: Http.Reply}
  Call{req: Http.Request}

# an effect's outcome on one connection: the value, or the line to log for
# a connection that is lost
type Got<-A: Type> is Type:
  Kept{value: A}
  Lost{line: String}

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

# For every failed accept, recv or send with reason `why`, the connection is
# lost with the log line exactly `ezhttp: <phase>: <why>`, phase `accept`,
# `read` or `write`; an effect that succeeds hands on its value unchanged.
# An accept whose deadline passes with no connection (ETIMEDOUT, 110) is
# neither: the server accepts again (`step.accepted`).
import Base
import ../src/step.bend as Step

# LAW: a failed accept or recv loses the connection with the line
# `ezhttp: <phase>: <why>`
law lost_failed:
  for -A: Type
  for phase: String
  for code: U32
  for why: String
  {Step.step.got(A, phase, Fail{(code, why)})
    == Step.Lost{"ezhttp: " ++ phase ++ ": " ++ why} : Step.Got<A>}

# LAW: an accept or recv that succeeds hands on its value unchanged
law lost_kept:
  for -A: Type
  for phase: String
  for value: A
  {Step.step.got(A, phase, Done{value}) == Step.Kept{value} : Step.Got<A>}

# LAW: a failed send loses the connection with the line `ezhttp: write: <why>`
law lost_send:
  for code: U32
  for why: String
  for left: List<&2, U32>
  {Step.step.sent(Fail{((code, why), left)})
    == Step.Lost{"ezhttp: write: " ++ why} : Step.Got<Unit>}

# LAW: a send that succeeds keeps the connection
law lost_sent:
  for done: Unit
  {Step.step.sent(Done{done}) == Step.Kept{done} : Step.Got<Unit>}

# --- the concurrent server's replies and accepts ---

# LAW: an accept whose deadline passed (ETIMEDOUT) is not a lost connection
law accept_idle:
  for -A: Type
  for +code: U32
  for e: {True{} == U32.is_eq(code, 110) : Bool}
  for why: String
  {Step.step.accepted(A, Fail{(code, why)}) == Step.Idle{} : Step.Accept<A>}

# LAW: any other failed accept is lost with the line `ezhttp: accept: <why>`
law accept_missed:
  for -A: Type
  for +code: U32
  for e: {False{} == U32.is_eq(code, 110) : Bool}
  for why: String
  {Step.step.accepted(A, Fail{(code, why)})
    == Step.Missed{"ezhttp: accept: " ++ why} : Step.Accept<A>}

# LAW: an accept that brought a connection hands it on unchanged
law accept_took:
  for -A: Type
  for value: A
  {Step.step.accepted(A, Done{value}) == Step.Took{value} : Step.Accept<A>}

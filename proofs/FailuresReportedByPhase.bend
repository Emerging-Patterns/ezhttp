# proofs of laws/FailuresReportedByPhase.bend
import Base
import ../src/wirespec.bend as Spec
import ../laws/FailuresReportedByPhase.bend as Laws

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

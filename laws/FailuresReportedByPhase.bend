# For every phase, host, port, deadline `ms`, error number `n` and reason
# `why` a failed resolve, connect, TLS handshake, send or receive gives, the
# exchange's answer (`wire.fail`) is: when `n` is ETIMEDOUT (110) and the
# phase is not the resolve, status 28 (laws/TimeoutsReadAsTimedOut.bend) and
# exactly `connecting to <host> port <port> took over <ms> ms`, `the TLS
# handshake with <host> took over <ms> ms`, `sending the request to <host>
# took over <ms> ms` or `<host> sent nothing for <ms> ms` for the connect,
# handshake, send and receive; otherwise status 6 and exactly `could not
# resolve <host>` when the resolve failed with ENOENT (2), which is how
# bend-kit-dns reports a name that has no address (an errno that would read
# as a missing file is left out), and `could not resolve <host>: <cause>`
# for every other number, status 7 and `could not reach <host> port <port>:
# <cause>`, status 35 and `the TLS handshake with <host> failed: <cause>:
# <why>`, status 55 and `the request to <host> could not be sent: <cause>`,
# or status 56 and `the answer from <host> was cut short: <cause>`, where
# the cause is `<name> (<n>)`, the name as laws/ErrnoNamesAreLinux.bend
# gives it.
import Base
import ../src/wirespec.bend as Spec

# LAW (laws/FailuresReportedByPhase.bend): a resolve that fails with any
# number but ENOENT is status 6 and names the host and the cause, ran out of
# time or not
law fail_resolve:
  for +host: String
  for +port: U32
  for +ms: U32
  for +n: U32
  for e: {False{} == U32.is_eq(n, 2) : Bool}
  for +why: String
  {Spec.wire.fail(Spec.Resolve{}, host, port, ms, n, why)
    == "6\ncould not resolve " ++ host ++ ": " ++ Spec.wire.cause(n) : String}

# LAW: a name with no address (ENOENT) is status 6 and the host alone
law fail_resolve_none:
  for +host: String
  for +port: U32
  for +ms: U32
  for +n: U32
  for e: {True{} == U32.is_eq(n, 2) : Bool}
  for +why: String
  {Spec.wire.fail(Spec.Resolve{}, host, port, ms, n, why)
    == "6\ncould not resolve " ++ host : String}

# LAW: a connect that ran out of time is status 28 and says how long it took
law fail_connect_late:
  for host: String
  for +port: U32
  for +ms: U32
  for +n: U32
  for e: {True{} == U32.is_eq(n, 110) : Bool}
  for why: String
  {Spec.wire.fail(Spec.Connect{}, host, port, ms, n, why)
    == "28\nconnecting to " ++ host ++ " port " ++ U32.show(port)
      ++ " took over " ++ U32.show(ms) ++ " ms" : String}

# LAW: a TLS handshake that ran out of time is status 28
law fail_handshake_late:
  for host: String
  for +port: U32
  for +ms: U32
  for +n: U32
  for e: {True{} == U32.is_eq(n, 110) : Bool}
  for why: String
  {Spec.wire.fail(Spec.Handshake{}, host, port, ms, n, why)
    == "28\nthe TLS handshake with " ++ host ++ " took over "
      ++ U32.show(ms) ++ " ms" : String}

# LAW: a send that ran out of time is status 28
law fail_send_late:
  for host: String
  for +port: U32
  for +ms: U32
  for +n: U32
  for e: {True{} == U32.is_eq(n, 110) : Bool}
  for why: String
  {Spec.wire.fail(Spec.Send{}, host, port, ms, n, why)
    == "28\nsending the request to " ++ host ++ " took over "
      ++ U32.show(ms) ++ " ms" : String}

# LAW: a receive that ran out of time is status 28
law fail_receive_late:
  for host: String
  for +port: U32
  for +ms: U32
  for +n: U32
  for e: {True{} == U32.is_eq(n, 110) : Bool}
  for why: String
  {Spec.wire.fail(Spec.Receive{}, host, port, ms, n, why)
    == "28\n" ++ host ++ " sent nothing for " ++ U32.show(ms) ++ " ms"
    : String}

# LAW: a connect that failed otherwise is status 7 and names host, port and
# cause
law fail_connect:
  for host: String
  for +port: U32
  for +ms: U32
  for +n: U32
  for e: {False{} == U32.is_eq(n, 110) : Bool}
  for why: String
  {Spec.wire.fail(Spec.Connect{}, host, port, ms, n, why)
    == "7\ncould not reach " ++ host ++ " port " ++ U32.show(port) ++ ": "
      ++ Spec.wire.cause(n) : String}

# LAW: a TLS handshake that failed otherwise is status 35, with the cause and
# the reason bend-kit-wire gave
law fail_handshake:
  for host: String
  for +port: U32
  for +ms: U32
  for +n: U32
  for e: {False{} == U32.is_eq(n, 110) : Bool}
  for why: String
  {Spec.wire.fail(Spec.Handshake{}, host, port, ms, n, why)
    == "35\nthe TLS handshake with " ++ host ++ " failed: "
      ++ Spec.wire.cause(n) ++ ": " ++ why : String}

# LAW: a send that failed otherwise is status 55
law fail_send:
  for host: String
  for +port: U32
  for +ms: U32
  for +n: U32
  for e: {False{} == U32.is_eq(n, 110) : Bool}
  for why: String
  {Spec.wire.fail(Spec.Send{}, host, port, ms, n, why)
    == "55\nthe request to " ++ host ++ " could not be sent: "
      ++ Spec.wire.cause(n) : String}

# LAW: a receive that failed otherwise is status 56
law fail_receive:
  for host: String
  for +port: U32
  for +ms: U32
  for +n: U32
  for e: {False{} == U32.is_eq(n, 110) : Bool}
  for why: String
  {Spec.wire.fail(Spec.Receive{}, host, port, ms, n, why)
    == "56\nthe answer from " ++ host ++ " was cut short: "
      ++ Spec.wire.cause(n) : String}

# LAW: a cause is the error number's name, then the number in parentheses
law cause_is:
  for +n: U32
  {Spec.wire.cause(n) == Spec.wire.errno.name(n) ++ " (" ++ U32.show(n) ++ ")"
    : String}

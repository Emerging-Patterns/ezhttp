# ezhttp server: IO handlers and per-connection failures

## Draft Status

Draft. Written from `83c7abb` (v0.8.0 + bend 2.0.36 pin). Nothing here is
decided; each REVIEW item below is a question for the maintainer, with a
recommendation. REVIEW-1 comes first because the rows' home depends on it.

- [ ] <!-- REVIEW-1 (open): ezhttp has no SPEC.md. Its LAWS.bend has 205 laws, 111 with a binder, and bolt.bend does not run `trace`. Recommend: adopt the convention first, as its own change (the bend-spec `adopting.md` route: inventory the existing laws into `HTTP-` rows, turn on `closed` and `trace`), and land this feature's rows into that SPEC.md afterwards. The alternative, landing these rows first in a SPEC.md that holds only the server, leaves the rest of the library looking unguaranteed when it is partly proved. -->
- [ ] <!-- REVIEW-2 (open): The name and shape of the IO entry point. Recommend `http.serve_io(~handle: Http.Request -> IO(Http.Reply), host, port, limit)` beside `http.serve`, with `http.serve` redefined as `serve_io` over `x => IO.pure(Http.Reply, handle(x))`, so the two cannot drift. The alternative, changing `http.serve` to take an IO handler, breaks every caller. Not a behavior change. -->
- [ ] <!-- REVIEW-3 (open): What a failed connection does to the server. Today any recv or send failure reaches `IO.pass` and the process exits (confirmed: a client that resets mid-body kills the server; see Background). Recommend: a failure on one connection closes that socket, writes one line to stderr and the loop takes the next connection, with the fuel it had. A failure to listen still exits, since nothing has started. Behavior change: `http.serve` stops exiting on per-connection failures. -->
- [ ] <!-- REVIEW-4 (open): A failed accept (EMFILE, ENFILE, ECONNABORTED). Recommend: the same as REVIEW-3, it costs one unit of fuel and the loop continues, after a fixed pause (100 ms) so a persistent EMFILE does not spin. The pause length is a constant in `server.bend`, not a row. -->
- [ ] <!-- REVIEW-5 (open): Serving without a limit. A server's loop has to count down fuel; `U32.to_nat(limit)` caps it at 2^32 - 1 connections, and a long-lived service (configs' shopsearch) writes its own `@unsafe` loop instead. Recommend: add `http.serve_forever` as an `@unsafe` def that calls the same per-connection step as `serve_io`, with a Trusted row saying the only unproved part is that it repeats; every decision it makes stays in the proved step. -->
- [ ] <!-- REVIEW-6 (open): Concurrency. Connections are served one at a time, and an IO handler that takes 30 s (a browser behind it) holds every other client in the backlog. Recommend: not in this feature. One-at-a-time is a real guarantee some callers rely on (shopsearch uses it to run one browser at a time), so a concurrent mode would be a separate entry point with a bound, specced on its own. This RFC states the sequential behavior as a row so a later change cannot drop it silently. -->

## Abstract

`http.serve` takes a pure `Request -> Reply` handler, so a server whose
answer needs IO (a subprocess, a file, an upstream call) cannot use it, and
any socket failure on any connection ends the process. We propose an IO
handler entry point that shares the reply logic with the pure one, a
per-connection step whose decisions are a pure planner the laws can reach,
and rows that state what happens after each kind of failure.

## Background

The server today (`src/server.bend`): `server.serve` listens, then
`server.loop.go` accepts up to `limit` connections, one at a time. Each
connection is read (`server.read`, chasing Content-Length for up to 64
recvs), answered by the pure handler through `server.reply` (400 for a
`Bad` request, HEAD bodies dropped, 204/304 bodies dropped), written, and
closed. Every effect's `Result` goes through `IO.pass`, so a `Fail` from
`TCP.accept`, `TCP.recv` or `TCP.send` becomes `IO.die`.

The motivating user is configs' shopsearch (`e71abb7`), a streamable-HTTP
MCP server that runs a browser helper with `Process.run` for each tool
call. It cannot use `http.serve`, so it rebuilds the loop from
`server.listen`, `server.accept`, `server.read` and `server.write` (all in
`src/`, which carries no promise) with its own `@unsafe` recursion. It
inherits the exit on failure. Measured against that build: a client that
sends half a request body and resets the connection makes the server print
`Connection reset by peer` and exit; the next connect is refused until
systemd restarts it 5 s later.

## Problem Statement

Goals:

- A handler can do IO, and the reply it returns is shaped exactly as a
  pure handler's would be (400 for bad requests, HEAD and 204/304 bodies).
- One connection's failure cannot end the server or touch another
  connection's exchange.
- Every decision the server makes after an effect returns is a pure
  function a quantified law can state.
- `http.serve` and `http.serve_once` keep their signatures.

Non-goals: concurrent connections (REVIEW-6), keep-alive, TLS on the
server, request timeouts (a slow client still holds the loop; worth its
own RFC, since the fix is `TCP.poll` with a deadline).

## Design

### One step, planned

The loop's body becomes one connection step. The IO wrapper runs effects
and decides nothing; after each effect it hands the outcome to a pure
planner, which says what to do next.

```
# what an effect in one connection step came back with
type Outcome is Data:
  Accepted{}
  AcceptFailed{why: String}
  Read{req: Http.Request}
  ReadFailed{why: String}
  Answered{reply: Http.Reply}
  Written{}
  WriteFailed{why: String}

# what the step does next
type Plan is Data:
  Handle{req: Http.Request}       # call the handler
  Write{reply: Http.Reply}        # send this, then close
  Drop{line: String}              # close the socket, log the line, next connection
  Pause{line: String}             # log, sleep, next connection (failed accept)
  Next{}                          # close, next connection

def server.plan(o: Outcome) -> Plan
```

`server.plan` is where the rows live: `Read{Bad{why}}` plans
`Write{400 reply}` and never `Handle`; `Read{Request{..}}` plans `Handle`;
`Answered{reply}` plans `Write` of `Http.reply.for(method, reply)`; every
`*Failed` plans `Drop` or `Pause`, never `Write` and never a stop. The
wrapper is a fixed sequence: accept, read, plan, maybe handle, plan,
write, plan, close, decrement fuel. A fuel unit is spent per accepted or
failed connection, never per recv, so `limit` counts connections as it
does today.

`server.read` changes in one place: a `Fail` from `TCP.recv` returns
`ReadFailed` instead of reaching `IO.pass`. `server.write` likewise returns
`WriteFailed`. Both keep their recv budget and fuel.

### Entry points

```
def http.serve_io(~handle: Http.Request -> IO(Http.Reply),
  host: String, port: U32, limit: U32) -> IO(Unit)
def http.serve(~handle: Http.Request -> Http.Reply,
  host: String, port: U32, limit: U32) -> IO(Unit)      # serve_io over IO.pure
@unsafe def http.serve_forever(~handle: Http.Request -> IO(Http.Reply),
  host: String, port: U32) -> IO(Unit)                    # REVIEW-5
```

### Logging

A `Drop` or `Pause` line goes to stderr, one line per failure:
`ezhttp: <phase>: <why>`, where phase is `accept`, `read` or `write`. The
planner builds the line, so its form is a row and not a convention.

## Proposed rows

Prefix `HTTP-SRV-`. All Proved, all pending until their laws land. The
laws quantify over `Outcome`, `Http.Request` and `Http.Reply`.

| ID | Requirement | Level | Status | Law |
| :-- | :-- | :-- | :-- | :-- |
| HTTP-SRV-1 | For every bad request, the step writes a 400 reply whose body is the reason, and the handler is not called. | Proved | pending | |
| HTTP-SRV-2 | For every well-formed request, the step calls the handler exactly once, with that request unchanged. | Proved | pending | |
| HTTP-SRV-3 | For every request method and handler reply, the reply written is `Http.reply.for(method, reply)`: a HEAD reply and a 204 or 304 reply are written with an empty body, and every other reply is written as the handler returned it. | Proved | pending | |
| HTTP-SRV-4 | For every pure handler `h` and request `r`, `http.serve` writes the same reply as `http.serve_io` with the handler `x => IO.pure(h(x))`. | Proved | pending | |
| HTTP-SRV-5 | For every failure of accept, recv or send, the plan writes nothing on that connection, closes it, and leaves the listener and the remaining fuel as they were before the connection. | Proved | pending | |
| HTTP-SRV-6 | For every failure, the plan's log line is exactly `ezhttp: <phase>: <why>`, with phase the effect that failed. | Proved | pending | |
| HTTP-SRV-7 | Connections are served one at a time: the step for one connection ends (written and closed, or dropped) before the next accept. | Proved | pending | |
| HTTP-SRV-8 | `serve_io` with limit `n` runs exactly `n` connection steps, counting failed ones, then closes the listener. | Proved | pending | |

| ID | Assumption | Why it is trusted |
| :-- | :-- | :-- |
| HTTP-TRUST-1 | Base's TCP effects report a failed accept, recv or send as `Fail` and return the handle, and never abort the process themselves. | Foreign C (`effs/tcp_*.c`) in Bend's runtime; no law reaches it. |
| HTTP-TRUST-2 | `http.serve_forever` repeats the HTTP-SRV-5..7 step without end. | It is `@unsafe` recursion, which the termination check does not cover; every decision inside the step is proved by the rows above. Only if REVIEW-5 is accepted. |

HTTP-SRV-7 is a statement about the wrapper's sequence, not the planner. It
is provable only if the wrapper is written as a fold of steps over fuel
with the step's result in its type; if that turns out not to be expressible,
it moves to the trust table with that reason, which is a review question
when it happens.

## Rollout

1. SPEC.md adoption (REVIEW-1), its own PR.
2. `server.plan` and `Outcome`/`Plan`, with HTTP-SRV-1, 2, 3, 5 and 6
   laws, and `server.read`/`server.write` returning failures. `http.serve`
   switches to the step: the behavior change of REVIEW-3, called out in
   the CHANGELOG.
3. `http.serve_io`, HTTP-SRV-4 and 8.
4. `http.serve_forever` and HTTP-TRUST-2, if REVIEW-5 is accepted.
5. Downstream: configs' shopsearch drops its own loop for
   `http.serve_forever` (or `serve_io` with a large limit) and imports only
   `main.bend`.

## Future Steps

- A request deadline (`TCP.poll`), so a slow client cannot hold the loop.
- A bounded concurrent entry point (REVIEW-6), with its own rows for what
  it gives up: ordering, and one-at-a-time handlers.

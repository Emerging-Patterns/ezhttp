# ezhttp specification

This is the list of behaviors ezhttp guarantees, each under a stable requirement ID. Every requirement has one of two levels. A **Proved** requirement holds for every input, and is backed by a quantified law (a `for` or `exs` binder) in LAWS.bend that passes the proof gate. A **Trusted** requirement is an assumption ezhttp cannot check from inside its own gate, and it is listed in the trust boundary below. A Proved requirement whose law has not landed yet has status **pending**: we intend to prove it, and until then it is not guaranteed. The proof gate is this check: the first line `bend PROOF.bend` prints is exactly `ALL PROOFS CHECK`. Tests and fixtures are never evidence for a requirement.

This file starts with the server and percent-encoding. ezhttp's other laws (URL parsing, message framing, credentials, cookies, caching, CORS) are not inventoried here yet, so this file promises nothing about them.

## Format

A requirement table is any table whose header row is exactly `| ID | Requirement | Level | Status | Law |`. An ID is uppercase segments joined by hyphens, at least two (`[A-Z][A-Z0-9]*(-[A-Z0-9]+)+`), unique within the requirement tables, and never reused once released. Level is `Proved` or `Trusted`. Status is `proved` or `pending` for a Proved row and empty for a Trusted row. A Law cell holds `<path> <law>` entries, paths relative to this file, separated by `; `. A Trusted row names none.

A law proves a requirement when a comment line `# <ID>`, alone on its line, sits in the unbroken comment block directly above its `law` line. A law may carry several tags, one per line.

## Requirements

### Server (HTTP-SRV)

The server's decisions live in `src/step.bend`, which does no IO; `src/server.bend` runs the effects and acts on them (HTTP-TRUST-2).

| ID | Requirement | Level | Status | Law |
| :---- | :---- | :---- | :---- | :---- |
| HTTP-SRV-1 | For every request that does not parse, with reason `why`, the server answers `400` with body `why` and does not call the handler. | Proved | proved | LAWS.bend step_bad |
| HTTP-SRV-2 | For every request that parses, the server calls the handler with that request, its method, target, headers and body unchanged. | Proved | proved | LAWS.bend step_call |
| HTTP-SRV-3 | For every reply, the server writes it with an empty body when the request method is exactly `HEAD` (RFC 9110 §9.3.2) or the status is 204 or 304 (RFC 9110 §15.3.5, §15.4.5), and writes its status, headers and body unchanged otherwise. | Proved | proved | LAWS.bend shape_head; LAWS.bend shape_other; LAWS.bend respond_204; LAWS.bend respond_304; LAWS.bend respond_other |
| HTTP-SRV-4 | For every failed accept, recv or send with reason `why`, the connection is lost with the log line exactly `ezhttp: <phase>: <why>`, phase `accept`, `read` or `write`; an effect that succeeds hands on its value unchanged. | Proved | proved | LAWS.bend lost_failed; LAWS.bend lost_kept; LAWS.bend lost_send; LAWS.bend lost_sent |
| HTTP-TRUST-1 | Base's TCP effects report a failed accept, recv or send as `Fail` and never end the process themselves. | Trusted | | |
| HTTP-TRUST-2 | `src/server.bend` acts on `src/step.bend`'s answers in order: one connection at a time; the handler is called only for a `Call`; a lost connection's line is written to stderr, the socket closed, and the loop takes the next connection; `http.serve` and `http.serve_io` stop after `limit` connections, a failed accept counting as one, and `http.serve_forever` does not stop. | Trusted | | |

### Percent-encoding (HTTP-URL)

`quote_path(s)` and `quote_component(s)` (`src/pct.bend`) percent-encode a string as RFC 3986 §2.1 describes, the way Python's `urllib.parse.quote(s)` and `urllib.parse.quote(s, safe="")` do. A character is a Unicode scalar value (U+0000 to U+10FFFF, no surrogates). Its UTF-8 encoding is the one RFC 3629 §3 tabulates.

| ID | Requirement | Level | Status | Law |
| :---- | :---- | :---- | :---- | :---- |
| HTTP-URL-1 | For every string, both forms write its characters in order, each one independently of the others; an unreserved character (RFC 3986 §2.3: `A`-`Z`, `a`-`z`, `0`-`9`, `-`, `.`, `_`, `~`) is written as itself. | Proved | proved | LAWS.bend quote_nil; LAWS.bend quote_cons; LAWS.bend one_unreserved |
| HTTP-URL-2 | Every character a form does not keep is written as `%XX` for each byte of its UTF-8 encoding, in order (RFC 3986 §2.1, RFC 3629 §3), `XX` being the byte's high then low nibble as hex digits `0`-`9` and upper-case `A`-`F`. | Proved | proved | LAWS.bend one_escaped; LAWS.bend pct_nil; LAWS.bend pct_cons; LAWS.bend hex_digit; LAWS.bend hex_letter; LAWS.bend utf8_one; LAWS.bend utf8_two; LAWS.bend utf8_three; LAWS.bend utf8_four |
| HTTP-URL-3 | The path form writes `/` as itself and the component form writes it as `%2F`; on every other character the two forms agree. | Proved | proved | LAWS.bend path_keeps_slash; LAWS.bend component_escapes_slash; LAWS.bend component_is_path_elsewhere |
| HTTP-URL-4 | For every string, the output holds only unreserved characters, `/` (path form only) and `%HH` triples whose `H` are `0`-`9` or `A`-`F`. | Proved | pending | LAWS.bend frame_kept; LAWS.bend frame_bytes; LAWS.bend frame_quote |

### Left to prove

| ID | Proved so far | Missing |
| :---- | :---- | :---- |
| HTTP-URL-4 | `frame_quote`: the whole output of either form is in the frame (kept characters, and `%` followed by exactly two upper-case hex digits, read left to right with nothing owed at the end), given `nibbles`: every character the form does not keep has UTF-8 bytes whose high and low nibbles `hex` writes as `0`-`9` or `A`-`F`. `frame_kept` and `frame_bytes` are its steps. | `nibbles` for every string of Unicode scalar values: each byte `utf8` yields for a code point up to U+10FFFF is below 256, so both nibbles are below 16, and `hex` of a value below 16 is a hex digit. This is bit arithmetic on `U32` (shifts, masks, comparisons on symbolic words) that Base has no lemmas for yet. |

## Trust boundary

| ID | Assumption | Why it is trusted |
| :---- | :---- | :---- |
| HTTP-TRUST-1 | Base's TCP effects report a failed accept, recv or send as `Fail` and never end the process themselves. | They are foreign C in Bend's runtime (`effs/tcp_*.c`), which no law reaches. |
| HTTP-TRUST-2 | `src/server.bend` acts on `src/step.bend`'s answers in order, as the requirement states. | It is IO sequencing: Base's effects are foreign, so the checker cannot run an IO program and no law can state what happens after an effect. Every decision it acts on is HTTP-SRV-1 to 4. `http.serve_forever` is also `@unsafe` recursion, outside the termination check. |

# ezhttp specification

This is the list of behaviors ezhttp guarantees, each under a stable requirement ID. Every requirement has one of two levels. A **Proved** requirement holds for every input, and is backed by a quantified law (a `for` or `exs` binder) in LAWS.bend that passes the proof gate. A **Trusted** requirement is an assumption ezhttp cannot check from inside its own gate, and it is listed in the trust boundary below. A Proved requirement whose law has not landed yet has status **pending**: we intend to prove it, and until then it is not guaranteed. The proof gate is this check: the first line `bend PROOF.bend` prints is exactly `ALL PROOFS CHECK`. Tests and fixtures are never evidence for a requirement.

This file starts with the server, percent-encoding, the client's timeout and redirects, and HTML escaping. ezhttp's other laws (URL parsing, message framing, credentials, cookies, caching, CORS) are not inventoried here yet, so this file promises nothing about them.

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

### Client timeout (HTTP-CLI)

`http.get_opts` takes a timeout in milliseconds. It travels to the wire effect in the spec `src/wirespec.bend` writes, where the scheme line may carry it after a space as 32 binary digits, least significant first; the effect honours it (HTTP-TRUST-3). What a failed exchange is reported as is decided in `src/wirespec.bend` too.

| ID | Requirement | Level | Status | Law |
| :---- | :---- | :---- | :---- | :---- |
| HTTP-CLI-1 | For every scheme, timeout `ms`, host, port and request, the timeout read back from the timed spec (`wire.ms`, which the effect follows) is exactly `ms`; from the spec every other client function sends, which carries none, it is 60000 ms. | Proved | proved | LAWS.bend spec_timed_ms; LAWS.bend spec_plain_ms |
| HTTP-CLI-2 | The timed spec differs from the untimed one only in its first line: the timed one's is the scheme, a space and the timeout, the untimed one's the scheme alone, and both then write host, port and request unchanged on the lines after. | Proved | proved | LAWS.bend spec_timed_lines; LAWS.bend spec_plain_lines |
| HTTP-CLI-3 | For every reason `why`, a failed exchange with wire status 28 (ran out of time) is reported as `Err` with reason exactly `timed out: <why>`, which `http.timed_out` recognizes; a failed exchange with any other status, or none, is reported with `why` unchanged. | Proved | proved | LAWS.bend why_late; LAWS.bend why_other; LAWS.bend why_none; LAWS.bend why_late_timed_out |
| HTTP-TRUST-3 | The wire effect (`src/effs/wire.c`, `wire.js`) reads the timeout as `wire.ms` does (a timeout of 0 as 1 ms) and bounds the connect, the TLS handshake, every send and every receive by it, each on its own as httpx's timeout does; name resolution is not bounded. It answers status 28 exactly when one of those calls runs out of time, and no reason it gives for another failure begins `timed out: `. | Trusted | | |

### Redirects (HTTP-REDIR)

`http.get_opts` with `follow` set follows redirects. GET is the only method that follows them, so every hop is a GET with the caller's headers and timeout. A chain is at most 10 hops (httpx allows 20); a chain that runs out answers its last response, a redirect. The decisions live in `src/redirect.bend`, which does no IO; `client.follow` in `src/client.bend` acts on them (HTTP-TRUST-4).

| ID | Requirement | Level | Status | Law |
| :---- | :---- | :---- | :---- | :---- |
| HTTP-REDIR-1 | For every status 301, 302, 303, 307 or 308 (RFC 9110 §15.4), with hops left, whose Location header (read case-insensitively, empty when absent) has a target, the next hop is a GET to exactly that target; a Location with no target stops the chain. | Proved | proved | LAWS.bend redir_go; LAWS.bend redir_no_target; LAWS.bend redir_plan_location |
| HTTP-REDIR-2 | Every other status stops the chain, and so does any response when no hops are left. | Proved | proved | LAWS.bend redir_other; LAWS.bend redir_zero |
| HTTP-REDIR-3 | A Location that starts `http://` or `https://` is its own target; one that starts with a single `/` is the current URL's scheme, `://`, host, `:`, port, then the Location, so scheme, host and port are kept (no target when the current URL does not parse); any other Location (empty, relative, `//host`) has no target. | Proved | proved | LAWS.bend target_absolute; LAWS.bend target_path; LAWS.bend target_path_bad; LAWS.bend target_other |
| HTTP-TRUST-4 | `client.follow` in `src/client.bend` sends a GET to the URL it is given, asks `redirect.plan` about the response with the hops it has left (10 to start), sends the next GET to a `Go` target with the same headers and timeout and one hop fewer, and answers the response on a `Stop`, on a failed exchange, or when no hops are left. | Trusted | | |

### HTML escaping (HTTP-HTML)

`html_escape(s)` (`src/html.bend`) escapes text for HTML the way markupsafe's `escape` and Jinja's autoescape do.

| ID | Requirement | Level | Status | Law |
| :---- | :---- | :---- | :---- | :---- |
| HTTP-HTML-1 | For every string, the escape writes its characters in order, each one independently of the others, and nothing else. | Proved | proved | LAWS.bend html_escape_onto; LAWS.bend html_nil; LAWS.bend html_cons |
| HTTP-HTML-2 | `&` is written as `&amp;`, `<` as `&lt;`, `>` as `&gt;`, `"` as `&#34;` and `'` as `&#39;`. | Proved | proved | LAWS.bend html_amp; LAWS.bend html_lt; LAWS.bend html_gt; LAWS.bend html_dq; LAWS.bend html_sq |
| HTTP-HTML-3 | Every other character is written as itself. | Proved | proved | LAWS.bend html_other |
| HTTP-HTML-4 | For every string, the output holds no `<`, `>`, `"` or `'`, and every `&` in it opens one of `&amp;`, `&lt;`, `&gt;`, `&#34;`, `&#39;`. | Proved | proved | LAWS.bend html_frame |

### Left to prove

| ID | Proved so far | Missing |
| :---- | :---- | :---- |
| HTTP-URL-4 | `frame_quote`: the whole output of either form is in the frame (kept characters, and `%` followed by exactly two upper-case hex digits, read left to right with nothing owed at the end), given `nibbles`: every character the form does not keep has UTF-8 bytes whose high and low nibbles `hex` writes as `0`-`9` or `A`-`F`. `frame_kept` and `frame_bytes` are its steps. | `nibbles` for every string of Unicode scalar values: each byte `utf8` yields for a code point up to U+10FFFF is below 256, so both nibbles are below 16, and `hex` of a value below 16 is a hex digit. This is bit arithmetic on `U32` (shifts, masks, comparisons on symbolic words) that Base has no lemmas for yet. |

## Trust boundary

| ID | Assumption | Why it is trusted |
| :---- | :---- | :---- |
| HTTP-TRUST-1 | Base's TCP effects report a failed accept, recv or send as `Fail` and never end the process themselves. | They are foreign C in Bend's runtime (`effs/tcp_*.c`), which no law reaches. |
| HTTP-TRUST-2 | `src/server.bend` acts on `src/step.bend`'s answers in order, as the requirement states. | It is IO sequencing: Base's effects are foreign, so the checker cannot run an IO program and no law can state what happens after an effect. Every decision it acts on is HTTP-SRV-1 to 4. `http.serve_forever` is also `@unsafe` recursion, outside the termination check. |
| HTTP-TRUST-3 | The wire effect honours the timeout the spec carries and reports running out of time as status 28, as the requirement states. | It is foreign C and JS (`src/effs/wire.c`, `wire.js`) over sockets and OpenSSL, which no law reaches. What the timeout is (HTTP-CLI-1) and what status 28 is reported as (HTTP-CLI-3) are proved. |
| HTTP-TRUST-4 | `client.follow` acts on `src/redirect.bend`'s hops in order, as the requirement states. | It is IO sequencing over the wire effect, which no law can state. Every decision it acts on is HTTP-REDIR-1 to 3. |

# ezhttp/src/packed: a response read off its packed octets (bend-kit-bytes),
# so its body is never turned into text. Only the heads and the chunk-size
# lines are read as text, a few octets each; every decision is
# src/http.bend's, the same one its text parse makes (SPEC.md HTTP-CLI-15):
# which head is final and what its plan is (head.final), its reason phrase
# (phrase.line), and what each chunk-size line says (chunk.size). This module
# only finds those lines and copies the body's octets out (SPEC.md
# HTTP-TRUST-9).
import Base
import bend-kit-bytes@0.3.2.0/bytes.bend as Bytes
import ./http.bend as Http

# a response read off its octets: torn, or its status, its header fields and
# reason phrase as octet text, and its body's octets
type Got is Type:  # noqa: L001 holds packed Bytes, which no law reaches (HTTP-TRUST-9)
  Torn{why: String}
  Got{status: U32, headers: List<&2, Http.Header>, reason: String,
    body: Bytes.Bytes}

# a chunked body's octets so far, newest first, or why it was torn
type Parts is Type:  # noqa: L001 holds packed Bytes, which no law reaches (HTTP-TRUST-9)
  Bad{why: String}
  Parts{parts: List<&1, Bytes.Bytes>}

# a slice's copy as text, the buffer kept
def packed.text.of(r: Bytes.Bytes & Bytes.Bytes) -> Bytes.Bytes & String:
  (b, piece) = r
  (b, Bytes.to_string(piece))

# n octets from `at` as text (a head or a chunk-size line), the buffer kept
def packed.text(b: Bytes.Bytes, +at: U32, +n: U32) -> Bytes.Bytes & String:
  packed.text.of(Bytes.slice(b, at, n))

# n octets from `at`, the buffer dropped
def packed.copy(b: Bytes.Bytes, +at: U32, +n: U32) -> Bytes.Bytes:
  Bytes.snd(Bytes.slice(b, at, n))

# --- a chunked body (RFC 9112 §7.1), as chunk.size decides ---

# a chunk's octets copied out, then on to the chunk-size line after its CRLF
def packed.chunk.take(r: Bytes.Bytes & Bytes.Bytes, +next: U32,
  acc: List<&1, Bytes.Bytes>,
  go: Bytes.Bytes -> U32 -> List<&1, Bytes.Bytes> -> Parts) -> Parts:
  (b, part) = r
  go(b)(next)(part <> acc)

# a chunk of k octets from d, ready when its CRLF follows them
def packed.chunk.ready.is(b: Bytes.Bytes, +d: U32, +k: U32,
  acc: List<&1, Bytes.Bytes>, ready: Bool,
  go: Bytes.Bytes -> U32 -> List<&1, Bytes.Bytes> -> Parts) -> Parts:
  match ready:
    case False{}:
      Bad{Http.chunk.short()}
    case True{}:
      packed.chunk.take(Bytes.slice(b, d, k), (d + k + 2 : U32), acc, go)

# a chunk of k octets from d whose CRLF has been looked for (chunks.ready)
def packed.chunk.ready(r: Bytes.Bytes & String, +d: U32, +k: U32,
  acc: List<&1, Bytes.Bytes>,
  go: Bytes.Bytes -> U32 -> List<&1, Bytes.Bytes> -> Parts) -> Parts:
  (b, crlf) = r
  packed.chunk.ready.is(b, d, k, acc, String.eq(crlf, "\r\n"), go)

# a chunk of n octets from d: its octets must all be there, and a CRLF after
# them
def packed.chunk.data(b: Bytes.Bytes, +d: U32, +n: Nat,
  acc: List<&1, Bytes.Bytes>, fits: Bool,
  go: Bytes.Bytes -> U32 -> List<&1, Bytes.Bytes> -> Parts) -> Parts:
  match fits:
    case False{}:
      Bad{Http.chunk.short()}
    case True{}:
      +k = U32.from_nat(n)
      packed.chunk.ready(packed.text(b, (d + k : U32), 2), d, k, acc, go)

# what a chunk-size line says, acted on with the octets after it
def packed.chunk.size(b: Bytes.Bytes, +d: U32, +len: U32,
  acc: List<&1, Bytes.Bytes>, z: Http.Size,
  go: Bytes.Bytes -> U32 -> List<&1, Bytes.Bytes> -> Parts) -> Parts:
  match z:
    case Http.SizeBad{why}:
      Bad{why}
    case Http.SizeLast{}:
      Parts{acc}
    case Http.SizeData{+n}:
      packed.chunk.data(b, d, n, acc,
        Bool.not(Nat.is_lt(U32.to_nat((len - d : U32)), Nat.add(n, 2n))), go)

# a chunk-size line read, its octets after its CRLF
def packed.chunk.line(r: Bytes.Bytes & String, +d: U32, +len: U32,
  acc: List<&1, Bytes.Bytes>,
  go: Bytes.Bytes -> U32 -> List<&1, Bytes.Bytes> -> Parts) -> Parts:
  (b, line) = r
  packed.chunk.size(b, d, len, acc, Http.chunk.size(line), go)

# a chunk-size line that ends at i, or none ends: the body ends there
def packed.chunk.at(r: Bytes.Bytes & Maybe<&2, U32>, +p: U32,
  +len: U32, acc: List<&1, Bytes.Bytes>,
  go: Bytes.Bytes -> U32 -> List<&1, Bytes.Bytes> -> Parts) -> Parts:
  (b, at) = r
  match at:
    case None{}:
      Parts{acc}
    case Some{+i}:
      packed.chunk.line(packed.text(b, p, (i - p : U32)), (i + 2 : U32),
        len, acc, go)

# the chunks from the chunk-size line at p, at most `fuel` of them
def packed.chunks(fuel: Nat, b: Bytes.Bytes, +p: U32, +len: U32,
  acc: List<&1, Bytes.Bytes>) -> Parts:
  match fuel:
    case 0n:
      Bad{"the chunked body is truncated"}
    case 1n+f:
      packed.chunk.at(Bytes.find.from(b, "\r\n", p), p, len, acc,
        b2 => q => a2 => packed.chunks(f, b2, q, len, a2))

# a chunked body's octets in order, or why it was torn
def packed.chunked(st: U32, hs: List<&2, Http.Header>, reason: String,
  r: Parts) -> Got:
  match r:
    case Bad{why}:
      Torn{why}
    case Parts{ps}:
      Got{st, hs, reason, Bytes.concat(List.reverse(&1, Bytes.Bytes, ps))}

# --- the body under its framing (RFC 9112 §6.3) ---

# a body framed by Content-Length: torn when fewer octets arrived
def packed.sized(st: U32, hs: List<&2, Http.Header>, reason: String,
  b: Bytes.Bytes, +q: U32, +n: Nat, short: Bool) -> Got:
  match short:
    case True{}:
      Torn{"the response body stopped before its Content-Length"}
    case False{}:
      Got{st, hs, reason, packed.copy(b, q, U32.from_nat(n))}

# the octets after the final head, as its framing says
def packed.body(st: U32, hs: List<&2, Http.Header>, reason: String,
  f: Http.Frame, b: Bytes.Bytes, +q: U32, +len: U32) -> Got:
  match f:
    case Http.Bare{}:
      Got{st, hs, reason, Bytes.new(0)}
    case Http.Sized{+n}:
      packed.sized(st, hs, reason, b, q, n,
        Nat.is_lt(U32.to_nat((len - q : U32)), n))
    case Http.Chunked{}:
      packed.chunked(st, hs, reason,
        packed.chunks(U32.to_nat((len - q : U32)), b, q, len, []))
    case Http.Closed{}:
      Got{st, hs, reason, packed.copy(b, q, (len - q : U32))}

# the final head's plan carried out on the octets after it
def packed.final(p: Http.Plan, reason: String, b: Bytes.Bytes, +q: U32,
  +len: U32) -> Got:
  match p:
    case Http.Unplanned{why}:
      Torn{why}
    case Http.Planned{st, hs, f}:
      packed.body(st, hs, reason, f, b, q, len)

# --- the heads (RFC 9112 §2.1, RFC 9110 §15.2) ---

# an interim head is skipped, any other is the final one
def packed.step(+asked: Bool, b: Bytes.Bytes, +q: U32, +len: U32,
  +ls: List<&2, String>, skip: Bool, rest: Bytes.Bytes -> U32 -> Got) -> Got:
  match skip:
    case True{}:
      rest(b)(q)
    case False{}:
      packed.final(Http.head.final(asked, ls), Http.phrase.line(Http.first(ls)),
        b, q, len)

# a head read as text, and the octets after its blank line from q
def packed.head.text(+asked: Bool, r: Bytes.Bytes & String, +q: U32,
  +len: U32, rest: Bytes.Bytes -> U32 -> Got) -> Got:
  (b, before) = r
  +ls = String.lines(before)
  packed.step(asked, b, q, len, ls,
    Http.interim.skip.of(Http.status.of(ls), U32.is_lt(q, len)), rest)

# a head that ends at i, or none ends
def packed.head(+asked: Bool, r: Bytes.Bytes & Maybe<&2, U32>, +p: U32,
  +len: U32, rest: Bytes.Bytes -> U32 -> Got) -> Got:
  (b, at) = r
  match at:
    case None{}:
      Torn{"the response head has no blank line after it"}
    case Some{+i}:
      packed.head.text(asked, packed.text(b, p, (i - p : U32)), (i + 4 : U32),
        len, rest)

# the heads in turn from p, at most `fuel` of them
def packed.heads(fuel: Nat, +asked: Bool, b: Bytes.Bytes, +p: U32, +len: U32)
  -> Got:
  match fuel:
    case 0n:
      Torn{"the response head has no blank line after it"}
    case 1n+f:
      packed.head(asked, Bytes.find.from(b, "\r\n\r\n", p), p, len,
        b2 => q => packed.heads(f, asked, b2, q, len))

# the response to a request with this method, its octets counted
def packed.reply.of(+method: String, r: Bytes.Bytes & U32) -> Got:
  (b, +len) = r
  packed.heads(U32.to_nat(len), String.eq(method, "HEAD"), b, 0, len)

# the response to a request with this method, read off its octets as
# parse.to reads its text (SPEC.md HTTP-CLI-9, HTTP-CLI-15, HTTP-TRUST-9)
def packed.reply(+method: String, b: Bytes.Bytes) -> Got:
  packed.reply.of(method, Bytes.length(b))

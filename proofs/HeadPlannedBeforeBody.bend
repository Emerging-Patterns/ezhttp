# proofs of laws/HeadPlannedBeforeBody.bend
import Base
import ../src/http.bend as Http
import ../laws/HeadPlannedBeforeBody.bend as Laws

# --- a response planned from its head ---

def Laws.plan_none(_ls):
  {==}

def Laws.plan_disagree(n, ls, e):
  %e : {Http.plan.agree(n, Http.head.list(ls), Http.head.go(ls, "transfer-encoding"),
    Http.head.values(ls, "content-length"), _)
    == Http.Unplanned{"Content-Length values disagree"} : Http.Plan}
  {==}

def Laws.plan_conflict(n, ls, e1, e2, e3):
  +V = Http.head.values(ls, "content-length")
  %e1 : {Http.plan.agree(n, Http.head.list(ls), Http.head.go(ls, "transfer-encoding"),
    V, _) == Http.Unplanned{"Content-Length and Transfer-Encoding conflict"} : Http.Plan}
  %e2 : {Http.plan.te(n, Http.head.list(ls), V,
      _) == Http.Unplanned{"Content-Length and Transfer-Encoding conflict"} : Http.Plan}
  %e3 : {Http.plan.clash(n, Http.head.list(ls),
      _) == Http.Unplanned{"Content-Length and Transfer-Encoding conflict"} : Http.Plan}
  {==}

def Laws.plan_chunked(n, ls, e1, e2, e3):
  +V = Http.head.values(ls, "content-length")
  %e1 : {Http.plan.agree(n, Http.head.list(ls), Http.head.go(ls, "transfer-encoding"),
    V, _) == Http.Planned{n, Http.head.list(ls), Http.Chunked{}} : Http.Plan}
  %e2 : {Http.plan.te(n, Http.head.list(ls), V, _) == Http.Planned{n, Http.head.list(ls), Http.Chunked{}} : Http.Plan}
  %e3 : {Http.plan.clash(n, Http.head.list(ls), _) == Http.Planned{n, Http.head.list(ls), Http.Chunked{}} : Http.Plan}
  {==}

def Laws.plan_sized(n, ls, e1, e2, k, e3):
  +V = Http.head.values(ls, "content-length")
  %e1 : {Http.plan.agree(n, Http.head.list(ls), Http.head.go(ls, "transfer-encoding"),
    V, _) == Http.Planned{n, Http.head.list(ls), Http.Sized{k}} : Http.Plan}
  %e2 : {Http.plan.te(n, Http.head.list(ls), V, _) == Http.Planned{n, Http.head.list(ls), Http.Sized{k}} : Http.Plan}
  %e3 : {Http.plan.len(n, Http.head.list(ls), _) == Http.Planned{n, Http.head.list(ls), Http.Sized{k}} : Http.Plan}
  {==}

def Laws.plan_closed(n, ls, e1, e2, e3):
  +V = Http.head.values(ls, "content-length")
  %e1 : {Http.plan.agree(n, Http.head.list(ls), Http.head.go(ls, "transfer-encoding"),
    V, _) == Http.Planned{n, Http.head.list(ls), Http.Closed{}} : Http.Plan}
  %e2 : {Http.plan.te(n, Http.head.list(ls), V, _) == Http.Planned{n, Http.head.list(ls), Http.Closed{}} : Http.Plan}
  %e3 : {Http.plan.len(n, Http.head.list(ls), _) == Http.Planned{n, Http.head.list(ls), Http.Closed{}} : Http.Plan}
  {==}

def Laws.plan_status(_m, _ls, _body):
  {==}

law final_of:
  for b: Bool
  for +m: Maybe<&2, U32>
  for +ls: List<&2, String>
  for +after: String
  {Http.parse.to.final(m, ls, after, b)
    == Http.plan.text(Http.head.final.of(b, m, ls), after) : Http.Reply}

def final_of(b, m, _ls, _after):
  match b:
    case True{}:
      match m:
        case None{}:
          {==}
        case Some{n}:
          {==}
    case False{}:
      {==}

def Laws.plan_final(f, head, before, after, e):
  +L = String.lines(before)
  +M = Http.status.of(L)
  %e : {Http.parse.to.step(head, L, M, after, _, cut => Http.parse.to.go(f, head, cut))
    == Http.plan.text(Http.head.final(head, L), after) : Http.Reply}
  final_of(Bool.or(head, Http.status.empty(M)), M, L, after)

law size_ready:
  for +after: String
  for +n: Nat
  for r: Bool
  {Http.chunks.next.of(False{}, r, after, n) == Http.chunk.next.data(after, n, r)
    : Http.Next}

def size_ready(_after, _n, r):
  match r:
    case True{}:
      {==}
    case False{}:
      {==}

law size_zero:
  for +n: Nat
  for +after: String
  for z: Bool
  {Http.chunks.next.of(z, Http.chunks.ready(after, n), after, n)
    == Http.chunk.next(Http.chunk.size.n(n, z), after) : Http.Next}

def size_zero(n, after, z):
  match z:
    case True{}:
      {==}
    case False{}:
      size_ready(after, n, Http.chunks.ready(after, n))

law size_hex:
  for +before: String
  for +after: String
  for ok: Bool
  {Http.chunks.next.hex(before, after, ok)
    == Http.chunk.next(Http.chunk.size.of(before, ok), after) : Http.Next}

def size_hex(before, after, ok):
  match ok:
    case False{}:
      {==}
    case True{}:
      size_zero(Http.hexlen(before), after, Nat.is_eq(Http.hexlen(before), 0n))

def Laws.size_next(before, after):
  size_hex(before, after, Http.hex.well(Http.chunks.token(before)))

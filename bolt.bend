# bolt.bend: how bolt lints this repo. See bolt/config.bend for groups and
# levels. `param` and `wrap` are warn: this port keeps ez net's short framing
# parameters and compact multi-line headers.
import Base

# what will fail or blow up
def correctness() -> String:
  "error"

# what is probably a slip
def suspicious() -> String:
  "error"

# comments and whitespace
def style() -> String:
  "error"

# single-letter parameters (ez net idiom)
def param() -> String:
  "warn"

# multi-line headers without one-param-per-line (ez net idiom)
def wrap() -> String:
  "warn"

# a pure def named by no law
def laws() -> String:
  "error"

# bolt 1.8.0 closed: warn until the findings are fixed (see the tracking issue)
def closed() -> String:
  "warn"

# a def no quantified law reaches. main.bend's re-exports, the bench program
# and src/client.bend's Response type (the wire effect keeps it out of every
# law file) carry `# noqa: L001` with the reason; dotted defs are helpers,
# which bolt never grades
def coverage() -> String:
  "error"

# SPEC.md rows and law tags agree (HTTP-SRV)
def trace() -> String:
  "error"

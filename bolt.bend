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
